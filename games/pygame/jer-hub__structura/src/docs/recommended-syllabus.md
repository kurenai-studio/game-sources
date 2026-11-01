# Recommended Syllabus: Data Structures and Algorithms (BSIT)

An 18-week semester with Prelim, Midterm and Final exams. It fits the BSIT DSA course (commonly CC 104 under CHED CMO No. 25, s. 2015). Check it against your approved course syllabus before adopting it. The course teaches Python and Java side by side, and every lab is done in both.

**How Structura fits in:** students play the Zone the same week the topic is lectured, then do the lab. Instructors collect Progress Reports through Google Classroom at each exam period and [combine them into one spreadsheet](combining-progress-reports.md).

| Week | Topic | Key ideas | Structura | Lab (Python + Java) |
|---|---|---|---|---|
| 1 | Course intro, abstract data types | ADT versus implementation; what "efficient" means | Create a Profile, try the Zone Map | Set up the environment; write the same small program in both languages |
| 2 | Algorithm analysis | Counting steps; Big-O, Big-Ω, Big-Θ; O(1), O(log n), O(n), O(n²) | — | Time a loop as n grows; plot the growth |
| 3 | Arrays and linear search | Indexing, contiguous memory, O(1) access, O(n) insert and delete | **Z1 Array Plains**: Lesson, *Find the Lantern*, *Gather the Grain* | Array insert and delete with shifting |
| 4 | Simple sorts and binary search | Bubble, selection and insertion sort (O(n²)); binary search (O(log n)) on sorted data | **Z1**: *Bubbling Up* and the other sort Puzzles, *The Sorted Road*, Boss *The Shuffler* | Implement all three sorts; count swaps and comparisons |
| 5 | Singly linked lists | Nodes and references, the head, O(1) insert at the head, O(n) access | **Z2 Linked Marshes**, Puzzles 1–4 | A linked list class: insert_head, insert_after, delete |
| 6 | **Prelim exam** | Weeks 1–5 | Collect Progress Report #1 (Z1–Z2) | — |
| 7 | Doubly and circular linked lists | prev pointers, a tail pointer, the trade-offs | **Z2** remaining Puzzles and Boss | Doubly linked list with a tail pointer |
| 8 | Stacks | LIFO, push/pop/peek, the call stack, checking balanced brackets | **Z3 Stack Towers** | Stack two ways: on an array and on a linked list; a bracket checker |
| 9 | Queues and deques | FIFO, circular buffer, deque | **Z4 Queue Canals** | Circular-buffer queue; simulate a ticket line |
| 10 | Recursion | Base case, the call stack, recursion versus iteration | — (not in Structura yet) | Factorial, sum of a list, recursive binary search |
| 11 | Choosing a structure; trees introduction | Comparing operation costs; tree terms; binary trees | **Nexus Alpha** (Select Puzzles, Boss *The Entropy Serpent*) | Pick and justify a structure for three scenarios |
| 12 | **Midterm exam** | Weeks 7–11 | Collect Progress Report #2 (Z2–Nexus Alpha) | — |
| 13 | Tree traversals and binary search trees | Pre-, in-, post- and level-order traversal; BST insert, search and delete (the successor rule) | **Z5 Binary Forest**, Puzzles 1–6 and 9 | A BST class with all three traversals |
| 14 | Balanced trees (AVL) | Balance factor; single and double rotations | **Z5** Optimize Puzzles and Boss *The Unbalanced Colossus* | Add rotations and AVL insert |
| 15 | Hash tables | Hash functions; collisions; chaining versus probing; O(1) average | Z6 Hash Bazaar *(planned)* | A hash map with chaining; compare it with the language's built-in map |
| 16 | Heaps and priority queues; efficient sorts | Heapify, insert and extract in O(log n); heap sort, merge sort, quick sort (O(n log n)) | Z8 Heap Forge *(planned)* | Min-heap, heap sort, merge sort |
| 17 | Graphs | Adjacency list versus matrix; BFS, DFS; Dijkstra using a priority queue | Z7 Graph Web *(planned)* | BFS and DFS on a campus map; Dijkstra |
| 18 | **Final exam** | Weeks 13–17 | Collect the final Progress Report | — |

## Differences from the original game plan

1. **Heaps come before graphs.** Dijkstra's algorithm needs a priority queue, so the Heap Zone should come before the Graph Zone. The original plan had them the other way round.
2. **Sorting is split in two.** The O(n²) sorts sit with arrays in week 4, matching Z1. The O(n log n) sorts need recursion, so they come in week 16, after recursion is taught.
3. **Recursion has no Zone.** Trees, merge sort and quick sort all depend on it. A future Zone or Lesson that shows the call stack, which ties nicely to the Stack Towers, would fill this gap.
4. **Doubly linked lists** are in this syllabus but not yet in the game. Z2 covers only singly linked lists.

## Assessment suggestion

| Component | Weight |
|---|---|
| Exams (Prelim, Midterm, Final) | 50% |
| Labs (Python and Java) | 30% |
| Structura Progress Reports (completion, not Stars) | 10% |
| Quizzes / recitation | 10% |

Grade Structura on **completion, not Stars**. Stars reward efficiency, and the game deliberately lets students fail and retry without penalty. Tying grades to Stars would push students to look up answers instead of exploring.
