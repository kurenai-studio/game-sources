# Copyright (C) 2026 Cassie Cass
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

"""
Version: 1.0
Author: Cassie Cass
License: GNU General Public License v3.0 (GPLv3)

---

CÓMO FUNCIONA EL JUEGO:
1. ARQUITECTURA MODULAR (POO): El juego está estructurado mediante clases que separan 
   responsabilidades: gestión de colores, formas geométricas, entidades (jugador y bloques), 
   control del tiempo (temporizadores), efectos físicos (gravedad) y el motor principal (Juego).
2. BUCLE PRINCIPAL (GAME LOOP): Se ejecuta a 60 FPS estables controlados por un objeto reloj. 
   En cada fotograma se procesan tres fases: eventos, física/lógica y renderizado.
3. FÍSICA Y COLISIONES: 
   - El jugador cae aplicando gravedad acumulativa de forma constante hasta colisionar con el suelo.
   - Se puede saltar con las teclas W o Flecha Arriba (siempre y cuando se esté apoyado en el suelo).
   - Los bloques rojos aparecen periódicamente en la parte superior y caen hacia el suelo, eliminándose 
     al tocarlo o terminando el juego si colisionan con el jugador.
4. SISTEMA DE PUNTUACIÓN: Un temporizador incrementa el puntaje en +1 cada segundo que el jugador 
   logre sobrevivir esquivando los bloques.
"""""

import pygame
import sys
import random
from basicos.colores import Color,GestorColores
from basicos.figuras import Figura,Rectangulo,Cuadrado
from basicos.gravedad import EfectoGravedad
from elementos.jugador import Jugador
from elementos.bloque import Bloque
from elementos.temporizador import Temporizador
from elementos.labels import Texto

# Motor principal del juego que inicializa la ventana, recursos y bucle de juego
class Juego():
    
    def __init__(self, ancho: int, alto: int, titulo: str, fps: int = 60):
        
        pygame.init()
        self.ANCHO = ancho
        self.ALTO  = alto

        self.ventana = pygame.display.set_mode((self.ANCHO, self.ALTO))
        pygame.display.set_caption(titulo)

        self.RELOJ = pygame.time.Clock()
        self.FPS = fps

    def administradorColores(self, gestorColores: GestorColores):
        
        self.GESTORCOLORES = gestorColores
        
    def play(self):
        
        en_ejecucion = True
        
        suelo = Rectangulo(500, 100, 0, 400, self.GESTORCOLORES.obtenerColor("GRIS"))
        jugador = Jugador(50, 50, 20, 340, self.GESTORCOLORES.obtenerColor("BLANCO"))
        gravedadJugador = EfectoGravedad(0, 0.5)
        
        posicionJugador = jugador.obtenerFigura()
        posicionSuelo = suelo.obtenerFigura()
        
        cronometro_enemigos = Temporizador(1000)
        cronometro_puntaje = Temporizador(1000)
        lista_bloques = []
        
        texto_del_puntaje = Texto("Puntaje: 0", True, self.GESTORCOLORES.obtenerColor("BLANCO"), "Arial", 20)
        
        puntaje = 0
        
        while en_ejecucion:
            
            # 1. GESTIÓN DE EVENTOS: Cierre de ventana, salida y detección de salto único
            for evento in pygame.event.get():
                if evento.type == pygame.QUIT:
                    en_ejecucion = False
                elif evento.type == pygame.KEYDOWN:
                    if evento.key == pygame.K_ESCAPE:
                        en_ejecucion = False
                    
                    # Salto limpio: solo si presiona W/Arriba y está en el suelo
                    if (evento.key == pygame.K_UP or evento.key == pygame.K_w) and not jugador.fueraDelSuelo:
                        gravedadJugador.VELOCIDAD_Y = -10  # Impulso negativo hacia arriba
                        jugador.fueraDelSuelo = True

            # 2. FÍSICA Y GRAVEDAD: Aplicación constante de aceleración y colisión con el suelo
            posicionJugador.y += gravedadJugador.gravedad()
            
            if posicionJugador.colliderect(posicionSuelo):
                if gravedadJugador.VELOCIDAD_Y > 0:
                    posicionJugador.bottom = posicionSuelo.top
                    jugador.fueraDelSuelo = False
                    gravedadJugador.VELOCIDAD_Y = 0  # Reseteamos la velocidad de caída

            # 3. MOVIMIENTO HORIZONTAL: Desplazamiento lateral del jugador y límites de pantalla
            teclas = pygame.key.get_pressed()
            
            if teclas[pygame.K_LEFT] or teclas[pygame.K_a]:
                posicionJugador.x -= jugador.movimiento
                if posicionJugador.x < 0:
                    posicionJugador.x = 0
            
            if teclas[pygame.K_RIGHT] or teclas[pygame.K_d]:
                posicionJugador.x += jugador.movimiento
                if posicionJugador.right >= self.ANCHO:
                    posicionJugador.right = self.ANCHO

            # Generación automática de bloques enemigos cada cierto tiempo
            if cronometro_enemigos.es_momento():
                
                for i in range(0, 4):
                    posicion_aleatoria_x = random.randint(0, self.ANCHO - 40)
                    nuevo_bloque = Bloque(50, 50, posicion_aleatoria_x, 20, self.GESTORCOLORES.obtenerColor("ROJO"))
                    lista_bloques.append(nuevo_bloque)
            
            # Actualización y chequeo de colisiones de los bloques activos
            for i in range(len(lista_bloques)-1, -1, -1):
                bloque = lista_bloques[i]
                figura = bloque.obtenerFigura()
                figura.y += 3
            
                # Si el bloque toca el suelo, se elimina de la lista
                if figura.colliderect(posicionSuelo):
                    lista_bloques.pop(i)
                    
                # Si el bloque toca al jugador, finaliza el juego
                if figura.colliderect(posicionJugador):
                    print(f"Puntuacion más alta: {puntaje}")
                    en_ejecucion = False
                    break
            
            # Incremento del puntaje basado en tiempo de supervivencia
            if cronometro_puntaje.es_momento():
                puntaje += 1
            
            # 4. RENDERIZADO: Limpieza de pantalla, dibujo de entidades, texto y actualización visual
            self.ventana.fill(self.GESTORCOLORES.obtenerColor("NEGRO"))
            
            pygame.draw.rect(self.ventana, suelo.COLOR, suelo.obtenerFigura())
            pygame.draw.rect(self.ventana, jugador.COLOR, jugador.obtenerFigura())
            
            texto_del_puntaje.cambiarTexto(f"Puntaje:{puntaje}")
            self.ventana.blit(texto_del_puntaje.obtenerTexto(), (10, 10))
            
            for bloque in lista_bloques:
                pygame.draw.rect(self.ventana, bloque.COLOR, bloque.obtenerFigura())
            
            pygame.display.flip()
            self.RELOJ.tick(self.FPS)

        pygame.quit()
        sys.exit()

def main():
    
    negro = Color("NEGRO",(0, 0, 0))
    gris = Color("GRIS",(100, 100, 100))
    blanco = Color("BLANCO",(255, 255, 255))
    rojo = Color("ROJO",(255, 0, 0))
    
    gestorColores = GestorColores()
    gestorColores.manejarColor(negro)
    gestorColores.manejarColor(gris)
    gestorColores.manejarColor(blanco)
    gestorColores.manejarColor(rojo)
    
    juego = Juego(500,500,"Mi primer juego",60)
    juego.administradorColores(gestorColores)
    juego.play()
    
main()