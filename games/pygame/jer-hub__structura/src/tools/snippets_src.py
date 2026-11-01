"""Source of truth for Code Mirror snippets. Run to regenerate
src/structura/codemirror/snippets/*. A trailing `@@kind[,kind]` marks the line
that runs when a model emits a Step of that kind (see ADR 0002)."""
from pathlib import Path

S: dict[str, tuple[str, str]] = {}

S["bubble_sort"] = ("""\
def bubble_sort(a):
    n = len(a)
    for end in range(n - 1, 0, -1):
        for i in range(end):
            if a[i] > a[i + 1]:  @@compare
                a[i], a[i + 1] = a[i + 1], a[i]  @@swap
""", """\
static void bubbleSort(int[] a) {
    for (int end = a.length - 1; end > 0; end--) {
        for (int i = 0; i < end; i++) {
            if (a[i] > a[i + 1]) {  @@compare
                int t = a[i]; a[i] = a[i + 1]; a[i + 1] = t;  @@swap
            }
        }
    }
}
""")

S["selection_sort"] = ("""\
def selection_sort(a):
    n = len(a)
    for i in range(n - 1):
        m = i
        for j in range(i + 1, n):
            if a[j] < a[m]:  @@compare
                m = j
        a[i], a[m] = a[m], a[i]  @@swap
""", """\
static void selectionSort(int[] a) {
    for (int i = 0; i < a.length - 1; i++) {
        int m = i;
        for (int j = i + 1; j < a.length; j++) {
            if (a[j] < a[m]) m = j;  @@compare
        }
        int t = a[i]; a[i] = a[m]; a[m] = t;  @@swap
    }
}
""")

S["insertion_sort"] = ("""\
def insertion_sort(a):
    for i in range(1, len(a)):
        j = i
        while j > 0 and a[j - 1] > a[j]:  @@compare
            a[j - 1], a[j] = a[j], a[j - 1]  @@swap
            j -= 1
""", """\
static void insertionSort(int[] a) {
    for (int i = 1; i < a.length; i++) {
        int j = i;
        while (j > 0 && a[j - 1] > a[j]) {  @@compare
            int t = a[j]; a[j] = a[j - 1]; a[j - 1] = t;  @@swap
            j--;
        }
    }
}
""")

S["swap"] = ("""\
# Swapping two cells is O(1), however big the array is.
def swap(a, i, j):
    out_of_order = a[i] > a[j]  @@compare
    a[i], a[j] = a[j], a[i]  @@swap
""", """\
// Swapping two cells is O(1), however big the array is.
static void swap(int[] a, int i, int j) {
    boolean outOfOrder = a[i] > a[j];  @@compare
    int t = a[i]; a[i] = a[j]; a[j] = t;  @@swap
}
""")

S["array_insert"] = ("""\
# Insert at index i is O(n): later cells shift right.
def insert(a, i, value):
    a.append(None)
    for k in range(len(a) - 1, i, -1):
        a[k] = a[k - 1]  @@shift
    a[i] = value  @@place
""", """\
// Insert at index i is O(n): later cells shift right.
static void insert(int[] a, int size, int i, int value) {
    for (int k = size; k > i; k--) {
        a[k] = a[k - 1];  @@shift
    }
    a[i] = value;  @@place
}
""")

S["array_delete"] = ("""\
# Delete at index i is O(n): later cells shift left.
def delete(a, i):
    removed = a[i]  @@remove
    for k in range(i, len(a) - 1):
        a[k] = a[k + 1]  @@shift
    a.pop()
    return removed
""", """\
// Delete at index i is O(n): later cells shift left.
static int delete(int[] a, int size, int i) {
    int removed = a[i];  @@remove
    for (int k = i; k < size - 1; k++) {
        a[k] = a[k + 1];  @@shift
    }
    return removed;
}
""")

S["linear_search"] = ("""\
def linear_search(a, target):
    for i in range(len(a)):
        if a[i] == target:  @@visit
            return i
    return -1
""", """\
static int linearSearch(int[] a, int target) {
    for (int i = 0; i < a.length; i++) {
        if (a[i] == target) return i;  @@visit
    }
    return -1;
}
""")

S["binary_search"] = ("""\
def binary_search(a, target):
    lo, hi = 0, len(a) - 1
    while lo <= hi:
        mid = (lo + hi) // 2
        if a[mid] == target:  @@visit
            return mid
        if a[mid] < target:
            lo = mid + 1
        else:
            hi = mid - 1
    return -1
""", """\
static int binarySearch(int[] a, int target) {
    int lo = 0, hi = a.length - 1;
    while (lo <= hi) {
        int mid = (lo + hi) / 2;
        if (a[mid] == target) return mid;  @@visit
        if (a[mid] < target) lo = mid + 1;
        else hi = mid - 1;
    }
    return -1;
}
""")

S["stack"] = ("""\
stack = []

def push(value):
    stack.append(value)  @@push

def pop():
    value = stack.pop()  @@pop
    top = stack[-1] if stack else None  @@new_top
    return value
""", """\
Deque<Integer> stack = new ArrayDeque<>();

void push(int value) {
    stack.push(value);  @@push
}

int pop() {
    int value = stack.pop();  @@pop
    Integer top = stack.peek();  @@new_top
    return value;
}
""")

S["queue"] = ("""\
from collections import deque
queue = deque()

def enqueue(value):
    queue.append(value)  @@enqueue

def dequeue():
    value = queue.popleft()  @@dequeue
    front = queue[0] if queue else None  @@new_front
    return value
""", """\
Queue<Integer> queue = new ArrayDeque<>();

void enqueue(int value) {
    queue.offer(value);  @@enqueue
}

int dequeue() {
    int value = queue.poll();  @@dequeue
    Integer front = queue.peek();  @@new_front
    return value;
}
""")

S["ll_insert_head"] = ("""\
class Node:
    def __init__(self, value):
        self.value = value
        self.next = None

def insert_head(head, value):
    node = Node(value)  @@new_node
    node.next = head  @@link_next
    return node  # new head  @@set_head
""", """\
class Node { int value; Node next; Node(int v) { value = v; } }

Node insertHead(Node head, int value) {
    Node node = new Node(value);  @@new_node
    node.next = head;  @@link_next
    return node; // new head  @@set_head
}
""")

S["ll_insert_after"] = ("""\
def insert_after(head, position, value):
    cur = head
    for _ in range(position):
        cur = cur.next  @@walk
    node = Node(value)  @@new_node
    node.next = cur.next  @@link_next
    cur.next = node  @@relink
""", """\
void insertAfter(Node head, int position, int value) {
    Node cur = head;
    for (int k = 0; k < position; k++) {
        cur = cur.next;  @@walk
    }
    Node node = new Node(value);  @@new_node
    node.next = cur.next;  @@link_next
    cur.next = node;  @@relink
}
""")

S["ll_delete"] = ("""\
def delete(head, position):
    if position == 0:
        return head.next  @@unlink_head
    cur = head
    for _ in range(position - 1):
        cur = cur.next  @@walk
    cur.next = cur.next.next  @@unlink
    return head
""", """\
Node delete(Node head, int position) {
    if (position == 0) return head.next;  @@unlink_head
    Node cur = head;
    for (int k = 0; k < position - 1; k++) {
        cur = cur.next;  @@walk
    }
    cur.next = cur.next.next;  @@unlink
    return head;
}
""")

S["ll_traverse"] = ("""\
def traverse(head):
    cur = head
    while cur is not None:
        visit(cur.value)  @@walk
        cur = cur.next
""", """\
void traverse(Node head) {
    for (Node cur = head; cur != null; cur = cur.next) {
        visit(cur.value);  @@walk
    }
}
""")

S["bst_insert"] = ("""\
def insert(root, value):
    if root is None:
        return Node(value)  @@place
    if value < root.value:  @@go_left
        root.left = insert(root.left, value)
    else:  @@go_right
        root.right = insert(root.right, value)
    return root
""", """\
Node insert(Node root, int value) {
    if (root == null) return new Node(value);  @@place
    if (value < root.value) {  @@go_left
        root.left = insert(root.left, value);
    } else {  @@go_right
        root.right = insert(root.right, value);
    }
    return root;
}
""")

S["bst_search"] = ("""\
def search(root, value):
    cur = root
    while cur is not None:
        if value == cur.value:  @@found,visit
            return cur
        if value < cur.value:  @@go_left
            cur = cur.left
        else:  @@go_right
            cur = cur.right
    return None
""", """\
Node search(Node root, int value) {
    Node cur = root;
    while (cur != null) {
        if (value == cur.value) return cur;  @@found,visit
        if (value < cur.value) cur = cur.left;  @@go_left
        else cur = cur.right;  @@go_right
    }
    return null;
}
""")

S["bst_delete"] = ("""\
def delete(root, value):
    if value < root.value:  @@go_left
        root.left = delete(root.left, value)
    elif value > root.value:  @@go_right
        root.right = delete(root.right, value)
    else:  @@found
        if root.left is None and root.right is None:
            return None  @@remove_leaf
        if root.left is None or root.right is None:
            return root.left or root.right  @@splice
        succ = root.right
        while succ.left is not None:
            succ = succ.left  @@find_successor,find_predecessor
        root.value = succ.value  @@replace
        root.right = delete(root.right, succ.value)
    return root
""", """\
Node delete(Node root, int value) {
    if (value < root.value) root.left = delete(root.left, value);  @@go_left
    else if (value > root.value) root.right = delete(root.right, value);  @@go_right
    else {  @@found
        if (root.left == null && root.right == null) return null;  @@remove_leaf
        if (root.left == null) return root.right;  @@splice
        if (root.right == null) return root.left;
        Node succ = root.right;
        while (succ.left != null) succ = succ.left;  @@find_successor,find_predecessor
        root.value = succ.value;  @@replace
        root.right = delete(root.right, succ.value);
    }
    return root;
}
""")

_ORDERS = {
    "preorder": ["visit(node.value)  @@visit", "walk(node.left)", "walk(node.right)"],
    "inorder": ["walk(node.left)", "visit(node.value)  @@visit", "walk(node.right)"],
    "postorder": ["walk(node.left)", "walk(node.right)", "visit(node.value)  @@visit"],
}
for _name, _body in _ORDERS.items():
    py = f"def walk(node):  # {_name}\n    if node is None:\n        return\n" + \
        "".join(f"    {line}\n" for line in _body)
    java = f"void walk(Node node) {{ // {_name}\n    if (node == null) return;\n" + \
        "".join("    " + line.replace(")  @@", ");  @@") + ("" if "@@" in line else ";") + "\n"
                for line in _body) + "}\n"
    S[f"bst_{_name}"] = (py, java)

S["bst_levelorder"] = ("""\
from collections import deque

def level_order(root):
    queue = deque([root])
    while queue:
        node = queue.popleft()
        visit(node.value)  @@visit
        if node.left: queue.append(node.left)
        if node.right: queue.append(node.right)
""", """\
void levelOrder(Node root) {
    Queue<Node> queue = new ArrayDeque<>(List.of(root));
    while (!queue.isEmpty()) {
        Node node = queue.poll();
        visit(node.value);  @@visit
        if (node.left != null) queue.add(node.left);
        if (node.right != null) queue.add(node.right);
    }
}
""")

S["bst_rotate"] = ("""\
def rotate_left(x):
    y = x.right
    x.right = y.left
    y.left = x  @@rotate_left
    return y  # y takes x's place

def rotate_right(x):
    y = x.left
    x.left = y.right
    y.right = x  @@rotate_right
    return y
""", """\
Node rotateLeft(Node x) {
    Node y = x.right;
    x.right = y.left;
    y.left = x;  @@rotate_left
    return y; // y takes x's place
}

Node rotateRight(Node x) {
    Node y = x.left;
    x.left = y.right;
    y.right = x;  @@rotate_right
    return y;
}
""")


if __name__ == "__main__":
    out = Path(__file__).resolve().parents[1] / "src" / "structura" / "codemirror" / "snippets"
    out.mkdir(parents=True, exist_ok=True)
    for old in out.glob("*.txt"):
        old.unlink()
    for key, (py, java) in S.items():
        (out / f"{key}.py.txt").write_text(py, encoding="utf-8")
        (out / f"{key}.java.txt").write_text(java, encoding="utf-8")
    print(f"wrote {len(S) * 2} snippet files")
