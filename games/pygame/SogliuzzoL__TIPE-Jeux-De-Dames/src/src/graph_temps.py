from matplotlib import pyplot as plt

file_name = "datas\\temps.csv"
sep = ";"

X = []
Y = []
Z = []

with open(file_name, 'r') as file:
    for line in file:
        X.append(int(line.split(sep)[0]))
        Y.append(int(line.split(sep)[1]))
        Z.append(float(line.split(sep)[2]))

meilleur_indice = Z.index(min(Z))
print(f'Meilleur modèle: Largeur = {X[meilleur_indice]}, Longueur = {Y[meilleur_indice]}')

ax = plt.axes(projection='3d')
ax.plot_trisurf(X, Y, Z, cmap='magma_r')
ax.set_xlabel('Largeur du modèle')
ax.set_ylabel('Longueur du modèle')
ax.set_zlabel('Temps')

plt.show()
