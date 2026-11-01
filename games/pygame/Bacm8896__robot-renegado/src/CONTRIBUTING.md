# Cómo ayudar a Robot Renegado

¡Gracias por pasarte! El juego está en desarrollo y lo que más ayuda ahora es **que lo juegues y cuentes qué te pareció**.

## 🎮 Jugaste y quieres opinar

No hace falta saber programar. Abre un [*issue*](../../issues/new/choose) y elige:

- **🐞 Algo falla:** un error, un cierre inesperado o algo que no hace lo que debería.
- **💡 Idea o mejora:** algo que le añadirías, cambiarías o quitarías: armas, enemigos, niveles, controles, dificultad, historia…

Cuanto más concreto, mejor: en qué parte del juego estabas, qué esperabas y qué pasó. Una captura o un video corto ayudan muchísimo.

## 💻 Quieres programar algo

1. Haz un *fork* del repositorio y crea una rama para tu cambio.
2. Instala las dependencias: `pip install -r requirements.txt`.
3. Antes de enviar, comprueba que todo sigue en verde:
   ```
   python smoke_test.py          # debe terminar en OK
   python src/verify_balance.py  # debe decir OK
   ```
4. Abre un *pull request* explicando qué cambia y por qué.

Para cambios grandes (mecánicas nuevas, reestructurar código) abre antes un *issue* para comentarlo.

**Reglas del código:**
- Los stats y el balance viven solo en `src/config/UNITS.py`: no pongas números sueltos en las clases.
- El arte se dibuja por código; los PNG en `assets/` son opcionales y deben funcionar si faltan.

## Licencia

Al contribuir aceptas que tu aporte se publique bajo la licencia [GPL-3.0](LICENSE) del proyecto.
