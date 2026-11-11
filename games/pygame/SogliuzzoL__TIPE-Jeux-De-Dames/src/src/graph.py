from matplotlib import pyplot as plt

file_name = "score_7x7.csv"
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

gen = []
moyenne_blancs = []
moyenne_noirs = []
mediane_blancs = []
mediane_noirs = []
ecart_type_blancs = []
ecart_type_noirs = []
max_blanc = []
max_noir = []


with open(file_name, 'r') as file:
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

plt.plot(gen, noirs)
plt.plot(gen, blancs)
plt.show()

