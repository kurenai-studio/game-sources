"""UpgradeManager (Prioridad 5): vista unificada del árbol del Operador y de sus rewards.

No guarda estado propio: lee y escribe en el ResourceManager (`op_nodes` para los nodos comprables y
`reward_tracker` para los rewards), así que el árbol del Terminal Táctico, los rewards y este gestor siempre coinciden.
Los bonus se calculan (no se acumulan): llamar dos veces a `apply_bonus` no los duplica. Los efectos reales los aplica
`Player.apply_upgrades` / `Player.refresh_rewards`; `active_bonuses` es el mismo resultado en el vocabulario de la UI."""
from src.config import UNITS as U

_CATEGORIES = {"OFENSIVA": "offensive", "SUPERVIVENCIA": "survival"}


class UpgradeManager:
    def __init__(self, res=None):
        if res is None:
            from src.managers.resource_manager import ResourceManager
            res = ResourceManager()
        self.res = res
        self._by_name = {spec["name"]: node for node, spec in U.OPERATOR_BONUSES.items()}
        self._reward_by_name = {name: rid for rid, name in U.REWARD_NODE_NAMES.items()}

    # --- resolución de nombres ---
    def _resolve(self, name):
        """(tipo, id): ("node", id del árbol) o ("reward", id del reward); (None, None) si no existe."""
        if name in U.OPERATOR_TREE:
            return "node", name
        if name in self._by_name:
            return "node", self._by_name[name]
        if name in self._reward_by_name:
            return "reward", self._reward_by_name[name]
        if name in U.REWARD_DEFINITIONS:
            return "reward", name
        return None, None

    def is_unlocked(self, name):
        kind, ident = self._resolve(name)
        if kind == "node":
            return ident in self.res.op_nodes
        return kind == "reward" and self.res.reward_tracker.is_unlocked(ident)

    # --- desbloqueo y bonus ---
    def unlock_node(self, name):
        """Desbloquea un nodo sin coste (los rewards lo hacen). False si ya estaba o no existe."""
        kind, ident = self._resolve(name)
        if kind == "node" and ident not in self.res.op_nodes:
            self.res.op_nodes.add(ident)
            return True
        if kind == "reward":
            return self.res.reward_tracker.add_reward(ident)
        return False

    def apply_bonus(self, name):
        """Aplica el bonus de un nodo desbloqueado (se recalcula en `active_bonuses`). False si sigue bloqueado."""
        return self.is_unlocked(name)

    def on_reward_unlocked(self, reward_id):
        """Un reward acaba de desbloquearse: los de Operador/dron figuran en el árbol con su nodo."""
        spec = U.REWARD_DEFINITIONS.get(reward_id)
        return bool(spec) and "operator_tree_node" in spec and self.res.reward_tracker.is_unlocked(reward_id)

    @property
    def active_bonuses(self):
        """Bonus vigentes en el vocabulario de la UI: suma de los nodos del árbol y de los rewards del Operador."""
        out = {}

        def add(key, value):
            if isinstance(value, bool):
                out[key] = out.get(key, False) or value
            elif key == "damage_reduction":                     # las reducciones se suman con tope (UNITS)
                out[key] = min(U.DAMAGE_REDUCTION_CAP, out.get(key, 0.0) + value)
            elif key == "regen_rate":                           # la regeneración de recompensa no se acumula: rige la mayor
                out[key] = max(out.get(key, 0), value)
            else:
                out[key] = out.get(key, 0) + value
        for node in self.res.op_nodes:
            for key, value in U.OPERATOR_BONUSES[node]["bonus"].items():
                add(key, value)
        for rid in self.res.reward_tracker.unlocked_rewards:
            spec = U.REWARD_DEFINITIONS[rid]
            if spec["type"] == "player_upgrade":
                for key, value in spec["bonus"].items():
                    add({"speed": "move_speed", "health_max": "health_max"}.get(key, key), value)
        return {k: (round(v, 6) if isinstance(v, float) else v) for k, v in out.items()}

    def get_bonus(self, bonus_key, default=0):
        return self.active_bonuses.get(bonus_key, default)

    def apply_player_upgrades(self, player):
        """Aplica al Operador el árbol y los rewards vigentes (lo hace Player; esto es el punto de entrada de la escena)."""
        player.apply_upgrades(self.res)

    # --- UI ---
    @property
    def upgrade_tree(self):
        """{categoría: {nombre: {unlocked, cost, bonus, description, parent, children}}} (vista viva del árbol)."""
        tree = {}
        for cat, branch in _CATEGORIES.items():
            nodes = {}
            for node, spec in U.OPERATOR_TREE.items():
                if spec["branch"] != branch:
                    continue
                children = [U.OPERATOR_BONUSES[n]["name"] for n, s in U.OPERATOR_TREE.items() if s["requires"] == node]
                nodes[U.OPERATOR_BONUSES[node]["name"]] = {
                    "name": U.OPERATOR_BONUSES[node]["name"], "label": spec["label"], "unlocked": node in self.res.op_nodes,
                    "cost": {"scrap": spec["cost"], "plasma_core": spec["cores"]}, "bonus": dict(U.OPERATOR_BONUSES[node]["bonus"]),
                    "description": spec["effect"], "parent": U.OPERATOR_BONUSES[spec["requires"]]["name"] if spec["requires"] else None,
                    "children": children}
            tree[cat] = nodes
        rewards = {}
        for rid, spec in U.REWARD_DEFINITIONS.items():
            if spec["type"] in ("player_upgrade", "drone_upgrade"):
                rewards[spec["operator_tree_node"]] = {
                    "name": spec["operator_tree_node"], "label": spec["name"], "reward": rid,
                    "unlocked": self.res.reward_tracker.is_unlocked(rid), "cost": {},
                    "bonus": dict(spec["bonus"]), "description": spec["description"], "parent": None, "children": []}
        tree["RECOMPENSAS"] = rewards
        return tree

    def get_tree_display(self):
        return {cat: {name: {k: v for k, v in info.items() if k in ("name", "unlocked", "cost", "description", "bonus")}
                      for name, info in nodes.items()} for cat, nodes in self.upgrade_tree.items()}
