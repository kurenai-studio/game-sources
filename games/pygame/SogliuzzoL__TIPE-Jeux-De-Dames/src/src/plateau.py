import time

import pygame.draw
import treelib.exceptions
from pygame import Surface
from treelib import Tree


class Pion:
    def __init__(self, emplacement, couleur, dame=False):
        """
        Cette fonction permet de créer un pion sur le plateau.
        :param emplacement: Emplacement du pion sur le plateau.
        :param couleur: Pion de couleur Blanc (0) ou Noir (1).
        """
        self.emplacement = emplacement
        self.color = couleur
        self.dame = dame


class Plateau:
    def __init__(self):
        """
        Création des données du plateau de jeu avec les pions des joueurs
        """
        self.coups_sans_prise = 0
        self.round_side = 0
        self.pions = []
        for i in range(1, 21):
            self.pions.append(Pion(i, 1))

        for i in range(31, 51):
            self.pions.append(Pion(i, 0))

    def positions(self) -> dict:
        """
        :return: Renvoie un dictionnaire avec pour clés les positions des pions et en valeurs leurs couleurs et leurs status de dame
        """
        positions = {}
        for pion in self.pions:
            positions[pion.emplacement] = [pion.color, pion.dame]
        return positions

    def check_win(self) -> int:
        """
        :return: Revoie -1 s'il n'y a pas de gagnant actuellement, 0 si les blancs ont gagné, 1 si les noirs ont gagné et 2 s'il y a égalité
        """
        if self.coups_sans_prise >= 25:
            return 2
        if len(coups_possibles(self.positions(), self.round_side)) == 0:
            if self.round_side:
                return 0
            else:
                return 1
        blanc_present = False
        noir_present = False
        for pion in self.pions:
            if pion.color:
                noir_present = True
            else:
                blanc_present = True
            if blanc_present and noir_present:
                return -1
        if blanc_present:
            return 0
        else:
            return 1

    def move_point(self, start_position: int, end_position: int):
        """
        :param start_position: Emplacement du point à déplacer.
        :param end_position: Emplacement où le point doit être déplacé.
        """
        for pion in self.pions:
            if pion.emplacement == start_position:
                if end_position == 0:
                    self.pions.remove(pion)
                else:
                    pion.emplacement = end_position
                    if pion.color and (end_position - 1) // 5 == 9 or not pion.color and (end_position - 1) // 5 == 0:
                        pion.dame = True
                break

    def jouer_coup(self, coup: str, couleur=0) -> bool:
        """
        :param coup: Le coup a effectué (doit être dans les coups possibles et doit être au même format).
        :param couleur: Couleur du joueur qui a effectué le coup.
        :return: Boolean qui informe si le coup a été effectué ou pas.
        """
        if coup in coups_possibles(self.positions(), couleur):
            """
            Variables
            """
            pion_mange = []
            start_case = 0
            end_case = 0
            if '-' in coup:
                """
                Cas où il n'y a pas de prise a effectué
                """
                temp_coup = coup.split('-')
                start_case = int(temp_coup[0])
                end_case = int(temp_coup[-1])
            else:
                """
                Cas où il y a une ou plusieurs prises
                """
                temp_coup = coup.split('x')
                start_case = temp_coup[0]
                end_case = temp_coup[-1]
                for i in range(len(temp_coup) - 1):
                    sub = int(temp_coup[i + 1]) - int(temp_coup[i])
                    if sub > 0:
                        case = int(temp_coup[i])
                        parity = (case - 1) // 5 % 2
                        while case + (6 - parity) < 51:
                            if case + (6 - parity) == int(temp_coup[i + 1]):
                                pion_mange.append(case)
                                break
                            case += (6 - parity)
                            parity = (case - 1) // 5 % 2
                        case = int(temp_coup[i])
                        parity = (case - 1) // 5 % 2
                        while case + (5 - parity) < 51:
                            if case + (5 - parity) == int(temp_coup[i + 1]):
                                pion_mange.append(case)
                                break
                            case += (5 - parity)
                            parity = (case - 1) // 5 % 2
                    if sub < 0:
                        case = int(temp_coup[i])
                        parity = (case - 1) // 5 % 2
                        while case - (5 + parity) > 0:
                            if case - (5 + parity) == int(temp_coup[i + 1]):
                                pion_mange.append(case)
                                break
                            case -= (5 + parity)
                            parity = (case - 1) // 5 % 2
                        case = int(temp_coup[i])
                        parity = (case - 1) // 5 % 2
                        while case - (4 + parity) > 0:
                            if case - (4 + parity) == int(temp_coup[i + 1]):
                                pion_mange.append(case)
                                break
                            case -= (4 + parity)
                            parity = (case - 1) // 5 % 2
            self.move_point(int(start_case), int(end_case))
            for case in pion_mange:
                self.move_point(int(case), 0)
            if not pion_mange:
                self.coups_sans_prise += 1
            else:
                self.coups_sans_prise = 0
            return True
        return False

    def plateau_information(self) -> dict:
        information = {'compte_noirs': 0, 'compte_blancs': 0, 'dames_noirs': 0, 'dames_blancs': 0, 'centre_noirs': 0,
                       'centre_blancs': 0}
        for pion in self.pions:
            if pion.color == 1:
                information['compte_noirs'] += 1
                if pion.dame:
                    information['dames_noirs'] += 1
                if 30 <= pion.emplacement <= 21:
                    information['centre_noirs'] += 1
            else:
                information['compte_blancs'] += 1
                if pion.dame:
                    information['dames_blancs'] += 1
                if 30 <= pion.emplacement <= 21:
                    information['centre_blancs'] += 1
        return information


def coups_prises_pions(case: int, positions: dict, couleur=0, tree=None, parent=None) -> Tree:
    """
    Cette fonction renvoie un arbre des prises possibles par un pion.
    Cette fonction est récursive !
    :param case: Case du preneur.
    :param positions: Dictionnaire des positions des pions sur le plateau.
    :param couleur: Couleur du joueur étant en train de jouer.
    :param tree: Arbre binaire servant à la fonction récursive.
    :param parent: Case parent servant à la fonction récursive.
    :return:
    """
    if tree is None:
        tree = Tree()
        tree.create_node(case, case)
        parent = case
    parity = ((case - 1) // 5) % 2
    datas = []
    if parity:
        datas = [[5, 11, 0], [4, 9, -1], [-5, -9, 0], [-6, -11, -1]]
    else:
        datas = [[6, 11, 0], [5, 9, -1], [-4, -9, 0], [-5, -11, -1]]
    for i in range(len(datas)):
        if case + datas[i][0] in positions.keys() and case + datas[i][1] not in positions.keys() and (
                case + datas[i][2]) % 5 != 0 and 0 < case + datas[i][1] <= 50:
            if positions[case + datas[i][0]][0] != couleur and 0 < case + datas[i][0] < 50:
                positions_copie = positions.copy()
                data = positions_copie[case]
                del positions_copie[case + datas[i][0]]
                positions_copie[case + datas[i][1]] = data
                try:
                    tree.create_node(f'{case}x{case + datas[i][1]}', f'{case}x{case + datas[i][1]}', parent=parent)
                except treelib.exceptions.DuplicatedNodeIdError:
                    tree.create_node(f'{case}x{case + datas[i][1]}-{time.perf_counter()}',
                                     f'{case}x{case + datas[i][1]}-{time.perf_counter()}', parent=parent)
                coups_prises_pions(case + datas[i][1], positions_copie, couleur, tree, f'{case}x{case + datas[i][1]}')
    return tree


def coup_prises_dames(case: int, positions: dict, couleur=0, tree=None, parent=None, disallowed_orientation=-1) -> Tree:
    """
    Cette fonction renvoie un arbre des prises possibles par une dame.
    Cette fonction est récursive !
    :param disallowed_orientation:
    :param case: Case de départ de la dame.
    :param positions: Positions des autres pions sur le plateau.
    :param couleur: Couleur de la dame.
    :param tree: Arbre binaire servant à la fonction récursive.
    :param parent: Case parent servant à la fonction récursive.
    :return: Renvoie un arbre binaire composé des coups possibles.
    """
    if tree is None:
        tree = Tree()
        tree.create_node(case, case)
        parent = case
    # En haut à gauche
    copy_positions = positions.copy()
    copy_case = case
    if copy_case in copy_positions:
        copy_positions.pop(copy_case)
    parity = (copy_case - 1) // 5 % 2
    while copy_case - (5 + parity) not in copy_positions and ((copy_case - 1) % 5 or parity == 0) and (
            copy_case - (5 + parity)) > 0 and disallowed_orientation != 0:
        copy_case -= (5 + parity)
        parity = (copy_case - 1) // 5 % 2
        if disallowed_orientation == 3:
            new = f"{case}>{copy_case}"
            try:
                tree.create_node(new, new, parent=parent)
            except treelib.exceptions.DuplicatedNodeIdError:
                new += f"-{time.perf_counter()}"
                tree.create_node(new, new, parent=parent)
            coup_prises_dames(copy_case, copy_positions, couleur, tree, new, 3)
    if copy_case - (5 + parity) in copy_positions and copy_case - 11 not in copy_positions and (
            (copy_case - 1) // 5 % 2) == (
            (copy_case - 12) // 5 % 2) and disallowed_orientation != 0 and copy_case - 11 > 0:
        if copy_positions[copy_case - (5 + parity)][0] != couleur:
            copy_positions.pop(copy_case - (5 + parity))
            copy_case -= 11
            new_parent = f"{case}x{copy_case}"
            try:
                tree.create_node(new_parent, new_parent, parent=parent)
            except treelib.exceptions.DuplicatedNodeIdError:
                new_parent += f"-{time.perf_counter()}"
                tree.create_node(new_parent, new_parent, parent=parent)
            coup_prises_dames(copy_case, copy_positions, couleur, tree, new_parent, 3)
    # En haut à droite
    copy_positions = positions.copy()
    copy_case = case
    if copy_case in copy_positions:
        copy_positions.pop(copy_case)
    parity = (copy_case - 1) // 5 % 2
    while copy_case - (4 + parity) not in copy_positions and (copy_case % 5 or parity == 1) and (
            copy_case - (4 + parity)) > 0 and disallowed_orientation != 1:
        copy_case -= (4 + parity)
        parity = (copy_case - 1) // 5 % 2
        if disallowed_orientation == 2:
            new = f"{case}>{copy_case}"
            try:
                tree.create_node(new, new, parent=parent)
            except treelib.exceptions.DuplicatedNodeIdError:
                new += f"-{time.perf_counter()}"
                tree.create_node(new, new, parent=parent)
            coup_prises_dames(copy_case, copy_positions, couleur, tree, new, 2)
    if copy_case - (4 + parity) in copy_positions and copy_case - 9 not in copy_positions and (
            (copy_case - 1) // 5 % 2) == (
            (copy_case - 10) // 5 % 2) and disallowed_orientation != 1 and copy_case - 9 > 0:
        if copy_positions[copy_case - (4 + parity)][0] != couleur:
            copy_positions.pop(copy_case - (4 + parity))
            copy_case -= 9
            new_parent = f"{case}x{copy_case}"
            try:
                tree.create_node(new_parent, new_parent, parent=parent)
            except treelib.exceptions.DuplicatedNodeIdError:
                new_parent += f"-{time.perf_counter()}"
                tree.create_node(new_parent, new_parent, parent=parent)
            coup_prises_dames(copy_case, copy_positions, couleur, tree, new_parent, 2)
    # En bas à gauche
    copy_positions = positions.copy()
    copy_case = case
    if copy_case in copy_positions:
        copy_positions.pop(copy_case)
    parity = (copy_case - 1) // 5 % 2
    while copy_case + (5 - parity) not in copy_positions and ((copy_case - 1) % 5 or parity == 0) and (
            copy_case + (5 - parity)) < 51 and disallowed_orientation != 2:
        copy_case += (5 - parity)
        parity = (copy_case - 1) // 5 % 2
        if disallowed_orientation == 1:
            new = f"{case}>{copy_case}"
            try:
                tree.create_node(new, new, parent=parent)
            except treelib.exceptions.DuplicatedNodeIdError:
                new += f"-{time.perf_counter()}"
                tree.create_node(new, new, parent=parent)
            coup_prises_dames(copy_case, copy_positions, couleur, tree, new, 1)
    if copy_case + (5 - parity) in copy_positions and copy_case + 9 not in copy_positions and (
            (copy_case - 1) // 5 % 2) == (
            (copy_case + 8) // 5 % 2) and disallowed_orientation != 2 and copy_case + 9 < 51:
        if copy_positions[copy_case + (5 - parity)][0] != couleur:
            copy_positions.pop(copy_case + (5 - parity))
            copy_case += 9
            new_parent = f"{case}x{copy_case}"
            try:
                tree.create_node(new_parent, new_parent, parent=parent)
            except treelib.exceptions.DuplicatedNodeIdError:
                new_parent += f"-{time.perf_counter()}"
                tree.create_node(new_parent, new_parent, parent=parent)
            coup_prises_dames(copy_case, copy_positions, couleur, tree, new_parent, 1)
    # En bas à droite
    copy_positions = positions.copy()
    copy_case = case
    if copy_case in copy_positions:
        copy_positions.pop(copy_case)
    parity = (copy_case - 1) // 5 % 2
    while copy_case + (6 - parity) not in copy_positions and (copy_case % 5 or parity == 1) and (
            copy_case + (6 - parity)) < 51 and disallowed_orientation != 3:
        copy_case += (6 - parity)
        parity = (copy_case - 1) // 5 % 2
        if disallowed_orientation == 0:
            new = f"{case}>{copy_case}"
            try:
                tree.create_node(new, new, parent=parent)
            except treelib.exceptions.DuplicatedNodeIdError:
                new += f"-{time.perf_counter()}"
                tree.create_node(new, new, parent=parent)
            coup_prises_dames(copy_case, copy_positions, couleur, tree, new, 0)
    if copy_case + (6 - parity) in copy_positions and copy_case + 11 not in copy_positions and (
            (copy_case - 1) // 5 % 2) == (
            (copy_case + 10) // 5 % 2) and disallowed_orientation != 3 and copy_case + 11 < 51:
        if copy_positions[copy_case + (6 - parity)][0] != couleur:
            copy_positions.pop(copy_case + (6 - parity))
            copy_case += 11
            new_parent = f"{case}x{copy_case}"
            try:
                tree.create_node(new_parent, new_parent, parent=parent)
            except treelib.exceptions.DuplicatedNodeIdError:
                new_parent += f"-{time.perf_counter()}"
                tree.create_node(new_parent, new_parent, parent=parent)
            coup_prises_dames(copy_case, copy_positions, couleur, tree, new_parent, 0)
    return tree


def coups_avancer_pions(case: int, positions: dict, couleur=0) -> list:
    """
    Cette fonction cherche les coups ne permettant pas une prise par un point.
    :param case: Case du point qui va avancer.
    :param positions: Dictionnaire contenant les positions des points étant sur le plateau.
    :param couleur: Couleur de joueur.
    :return: Revoie une liste contenant les coups possibles par les points.
    """
    coups = []
    modifier_couleur = 1
    modifier_couleur2 = 0
    parity = ((case - 1) // 5) % 2
    if couleur == 0:
        modifier_couleur = -1
        if parity:
            modifier_couleur2 = -1
        else:
            modifier_couleur2 = 1
    if (case // 5) % 2 == 1 and case % 5 == 0 or (case // 5) % 2 == 1 and case % 5 == 1:
        if case + 5 * modifier_couleur not in positions: coups.append(f'{case}-{case + 5 * modifier_couleur}')
    else:
        if case + (5 - parity) * modifier_couleur + modifier_couleur2 not in positions:
            coups.append(f'{case}-{case + (5 - parity) * modifier_couleur + modifier_couleur2}')
        if case + (6 - parity) * modifier_couleur + modifier_couleur2 not in positions:
            coups.append(f'{case}-{case + (6 - parity) * modifier_couleur + modifier_couleur2}')
    return coups


def coups_avancer_dames(case, positions):
    coups = []
    # Avancer en haut à gauche
    case_temp = case
    parity = ((case_temp - 1) // 5) % 2
    while ((case_temp - 1) % 5 != 0 or ((case_temp - 1) // 5) % 2 == 0) and (case_temp > 5) and (
            (case_temp - 5 - parity) not in positions.keys()):
        case_temp -= 5 + parity
        parity = ((case_temp - 1) // 5) % 2
        coups.append(f'{case}-{case_temp}')

    # Avancer en haut à droite
    case_temp = case
    parity = ((case_temp - 1) // 5) % 2
    while (case_temp % 5 != 0 or ((case_temp - 1) // 5) % 2 == 1) and (case_temp > 5) and (
            (case_temp - 4 - parity) not in positions.keys()):
        case_temp -= 4 + parity
        parity = ((case_temp - 1) // 5) % 2
        coups.append(f'{case}-{case_temp}')

    # Avancer en bas à gauche
    case_temp = case
    parity = ((case_temp - 1) // 5) % 2
    while ((case_temp - 1) % 5 != 0 or ((case_temp - 1) // 5) % 2 == 0) and (case_temp < 46) and (
            (case_temp + 5 - parity) not in positions.keys()):
        case_temp += 5 - parity
        parity = ((case_temp - 1) // 5) % 2
        coups.append(f'{case}-{case_temp}')

    # Avancer en bas à droite
    case_temp = case
    parity = ((case_temp - 1) // 5) % 2
    while (case_temp % 5 != 0 or ((case_temp - 1) // 5) % 2 == 1) and (case_temp < 46) and (
            (case_temp + 6 - parity) not in positions.keys()):
        case_temp += 6 - parity
        parity = ((case_temp - 1) // 5) % 2
        coups.append(f'{case}-{case_temp}')

    return coups


def coups_possibles(positions: dict, couleur=0):
    """
    Cette fonction retourne tous les coups possibles en fonctions des positions des autres pions.
    :param couleur: Couleurs du joueur du tour
    :param positions: Dictionnaire avec la position d'un pion en clé et avec les informations du pion en valeurs.
    :return: Liste des coups possibles.
    """
    coups = []
    coups_tempo = []
    max_coups = 0
    # Prises
    for case in positions.keys():
        if positions[case][0] == couleur:
            if not positions[case][1]:
                tree = coups_prises_pions(case, positions, couleur)
                if tree.depth():
                    paths = tree.paths_to_leaves()
                    for path in paths:
                        if max_coups < len(path):
                            max_coups = len(path)
                        coups_tempo.append(path)
            else:
                tree = coup_prises_dames(case, positions, couleur)
                if tree.depth():
                    paths = tree.paths_to_leaves()
                    for path in paths:
                        if max_coups < len(path):
                            temp_max = 1
                            k = -1
                            for i in range(1, len(path)):
                                if 'x' in path[i]:
                                    temp_max += 1
                            if max_coups < temp_max:
                                max_coups = temp_max
                            while '>' in path[k]:
                                if path[0:k] not in coups_tempo:
                                    coups_tempo.append(path[0:k])
                                k -= 1
                        coups_tempo.append(path)

    # Trie des coups pour prises
    for i in range(len(coups_tempo)):
        if len(coups_tempo[i]) >= max_coups:
            k = -1
            while '>' in coups_tempo[i][k]:
                k -= 1
            if len(coups_tempo[i]) + k + 1 < max_coups:
                continue
            real_coup_number = 1
            for j in range(1, len(coups_tempo[i])):
                if 'x' in coups_tempo[i][j]:
                    real_coup_number += 1
            if real_coup_number < max_coups:
                continue
            for j in range(len(coups_tempo[i])):
                if '-' in str(coups_tempo[i][j]):
                    split = str(coups_tempo[i][j]).split('-')
                    coups_tempo[i][j] = split[0]
            coups_tempo[i].remove(coups_tempo[i][0])
            coups.extend(coups_tempo[i])
    i = 0
    while i < len(coups) - 1:
        coup1 = coups[i].split('x')
        if '>' in coups[i + 1]:
            coup2 = coups[i + 1].split('>')
        else:
            coup2 = coups[i + 1].split('x')
        if coup1[-1] == coup2[0]:
            coups.remove(coups[i])
            coups.remove(coups[i])
            real_coup = coup1[0]
            for j in range(1, len(coup1)):
                real_coup += 'x' + coup1[j]
            for j in range(1, len(coup2)):
                real_coup += 'x' + coup2[j]
            coups.insert(i, real_coup)
            i -= 1
        i += 1
    # Avancer
    if len(coups) == 0:
        for case in positions.keys():
            if not positions[case][1] and positions[case][0] == couleur:
                coups.extend(coups_avancer_pions(case, positions, couleur))
            elif positions[case][1] and positions[case][0] == couleur:
                coups.extend(coups_avancer_dames(case, positions))
    return coups


def affichage_plateau(plateau: Plateau, screen: Surface, case_depart: int):
    positions = plateau.positions()
    white_case_color = (230, 240, 245)
    black_case_color = (25, 15, 10)
    white_pion_color = (247, 198, 72)
    black_pion_color = (129, 84, 71)
    white_dame_color = (217, 168, 42)
    black_dame_color = (159, 114, 101)
    white_color = (255, 255, 255)
    screen_size = screen.get_size()
    case_size = screen_size[1] / 10
    start_x = (screen_size[0] - screen_size[1]) / 2
    font = pygame.font.SysFont(pygame.font.get_fonts()[0], 24)
    for i in range(10):
        for j in range(10):
            if (i + j) % 2:
                pygame.draw.rect(screen, black_case_color,
                                 (start_x + i * case_size, j * case_size, case_size, case_size))
                text = font.render(str((i + j * 10) // 2 + 1), True, (125, 125, 125))
                screen.blit(text, (start_x + i * case_size, j * case_size))
            else:
                pygame.draw.rect(screen, white_case_color,
                                 (start_x + i * case_size, j * case_size, case_size, case_size))
    for key in positions.keys():
        pion_color = positions[key][0]
        pion_dame = positions[key][1]
        case_x = (key * 2 - 1) % 10
        case_y = (key - 1) * 2 // 10
        real_case = case_x // 2 + 1 + 5 * case_y
        if case_y % 2:
            case_x -= 1
        if real_case == case_depart:
            pygame.draw.circle(screen, white_color,
                               (start_x + case_x * case_size + case_size // 2, case_y * case_size + case_size // 2),
                               case_size * 0.98 // 2)
        if pion_color:
            pygame.draw.circle(screen, black_pion_color,
                               (start_x + case_x * case_size + case_size // 2, case_y * case_size + case_size // 2),
                               case_size * 0.95 // 2)
            if pion_dame:
                pygame.draw.circle(screen, black_dame_color,
                                   (start_x + case_x * case_size + case_size // 2, case_y * case_size + case_size // 2),
                                   case_size * 0.75 // 2)
        else:
            pygame.draw.circle(screen, white_pion_color,
                               (start_x + case_x * case_size + case_size // 2, case_y * case_size + case_size // 2),
                               case_size * 0.95 // 2)
            if pion_dame:
                pygame.draw.circle(screen, white_dame_color,
                                   (start_x + case_x * case_size + case_size // 2, case_y * case_size + case_size // 2),
                                   case_size * 0.75 // 2)


def display_coup(coups: list) -> list:
    real_coup = []
    for coup in coups:
        if 'x' in coup:
            split = coup.split('x')
            if f'{split[0]}x{split[-1]}' not in real_coup:
                real_coup.append(f'{split[0]}x{split[-1]}')
        else:
            split = coup.split('-')
            if f'{split[0]}-{split[-1]}' not in real_coup:
                real_coup.append(f'{split[0]}-{split[-1]}')
    return real_coup
