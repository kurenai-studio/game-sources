# -*- coding: utf-8 -*-
"""
Created on Tue Nov  2 09:54:31 2021

@author: eljac
"""
import numpy as np

with open('formatted_oxford_dictionary_word_list.txt', 'r', encoding='utf-8') as fl:
    data = fl.readlines()

data2 = [line.split()[0].upper() for line in data if len(line) > 4]

# Exclude words with special characters or too short
words_list = []
alphabet = list("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
for word in data2:
    if len(word) > 4:
        if all(x in alphabet for x in word):
            words_list.append(word)

words = np.unique(words_list)

with open('formatted_oxford_dictionary_word_list_new.txt', 'w+', encoding='utf-8') as fl:
    for word in words:
        fl.write(word + '\t' + str(len(word)) + '\n')

