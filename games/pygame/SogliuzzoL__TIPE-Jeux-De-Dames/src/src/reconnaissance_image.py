import matplotlib.image as iplt
import matplotlib.pyplot as plt
import numpy as np

image_datas = iplt.imread('jeudedames.jpg')

print(image_datas[0, 0])

conversion = [0.2989, 0.5870, 0.1140]
gray_image = np.dot(image_datas[:, :], conversion)

plt.imshow(gray_image, cmap='gray', vmin=0, vmax=255)
plt.show()

image_datas = iplt.imread('jeudedames2.jpg')

print(image_datas[0, 0])

conversion = [0.2989, 0.5870, 0.1140]
gray_image = np.dot(image_datas[:, :], conversion)

plt.imshow(gray_image, cmap='gray', vmin=0, vmax=255)
plt.show()
