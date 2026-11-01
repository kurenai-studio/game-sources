#include "snake.h"

node_t * createHead(node_t * next, Vector2 position)
{
   node_t * head = (node_t *) malloc(sizeof(node_t));

   // Make it point to the next node
   head->next = next;
   head->position = position;

   return head;
}

node_t * deleteTail(node_t * head)
{
   node_t * current = head;

   while (current->next->next != NULL)
   {
      current = current->next;
   }

   node_t * deleted = current->next;

   free(current->next);
   current->next = NULL;

   return deleted;
}

void deleteSnake(node_t * head)
{
   node_t * current = head;

   while (current != NULL)
   {
      node_t * next = current->next;
      free(current);
      current = next;
   }
}

void forEach(node_t * head, void (*callback)(node_t * node))
{
   node_t * current = head;

   while (current != NULL)
   {
      callback(current);
      current = current->next;
   }
}

int isColliding(node_t * head, Vector2 position)
{
   node_t * current = head;

   while (current != NULL)
   {
      if (current->position.x == position.x && current->position.y == position.y)
      {
         return 1;
      }
      current = current->next;
   }

   return 0;
}
