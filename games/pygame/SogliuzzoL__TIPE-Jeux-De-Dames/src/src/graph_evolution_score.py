import os

import numpy as np
from matplotlib import pyplot as plt

file_dir = "datas\\"
sep = ";"
start = "score_"
end = ".csv"

n_moyenne_glissante = 10


def lissage_courbe(l):
    moyenne_glissante = []
    for i in range(len(l)):
        somme = 0
        for j in range(min(i, n_moyenne_glissante)):
            somme += l[i - j]
        somme /= n_moyenne_glissante
        moyenne_glissante.append(somme)
    return moyenne_glissante


X = []
Y = []
Z = []
dict_largeur = {}
dict_longueur = {}
surface = False

for file in os.listdir(file_dir):
    gen = []
    moyenne_blancs = []
    moyenne_noirs = []
    mediane_blancs = []
    mediane_noirs = []
    ecart_type_blancs = []
    ecart_type_noirs = []
    max_blanc = []
    max_noir = []
    if file[:len(start)] == start and file[-len(end):] == end:
        with open(file_dir + file, 'r') as file:
            for line in file:
                line_sep = line.split(sep)
                gen.append(int(line_sep[0]))
                moyenne_blancs.append(float(line_sep[1]))
                moyenne_noirs.append(float(line_sep[2]))
                mediane_blancs.append(float(line_sep[3]))
                mediane_noirs.append(float(line_sep[4]))
                ecart_type_blancs.append(float(line_sep[5]))
                ecart_type_noirs.append(float(line_sep[6]))
                max_blanc.append(float(line_sep[7]))
                max_noir.append(float(line_sep[8].replace("\n", "")))
        noirs = lissage_courbe(moyenne_noirs)
        blancs = lissage_courbe(moyenne_blancs)
        moyenne = []
        for i in range(len(noirs)):
            moyenne.append((noirs[i] + blancs[i]) / 2)
        largeur = int(file.name.split('\\')[-1].split('x')[0].replace(start, ''))
        longueur = int(file.name.split('x')[-1].split('.')[0])
        score = np.mean([lissage_courbe(moyenne_noirs)[-1], lissage_courbe(moyenne_blancs)[-1]])
        X.append(longueur)
        Y.append(largeur)
        Z.append(score)
        if longueur in dict_longueur:
            dict_longueur[longueur].append(score)
        else:
            dict_longueur[longueur] = [score]

        if largeur in dict_largeur:
            dict_largeur[largeur].append(score)
        else:
            dict_largeur[largeur] = [score]

for key in dict_longueur.keys():
    dict_longueur[key] = np.mean(dict_longueur[key])

for key in dict_largeur.keys():
    dict_largeur[key] = np.mean(dict_largeur[key])

meilleur_indice = Z.index(max(Z))
print(f'Meilleur modèle: Longueur = {X[meilleur_indice]}, Largeur={Y[meilleur_indice]}')
if surface and len(dict_longueur.keys()) > 1 and len(dict_largeur.keys()) > 1:
    fig, ax = plt.subplots(subplot_kw={'projection': '3d'})
    ax.plot_trisurf(X, Y, Z, cmap='magma')
else:
    plt.subplot(211)
    plt.scatter(dict_longueur.keys(), dict_longueur.values(), label='Score en fonction de la longueur')
    plt.legend()

    plt.subplot(212)
    plt.scatter(dict_largeur.keys(), dict_largeur.values(), label='Score en fonction de la largeur')
    plt.legend()

plt.show()
