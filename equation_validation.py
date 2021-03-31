import numpy as np
from numpy.linalg import inv
import networkx as nx
import scipy as sp
import matplotlib.pyplot as plt



def get_W(G):
    ### get propagation matrix ###
    A = nx.adjacency_matrix(G).toarray()
    M = nx.laplacian_matrix(G).toarray()
    D = M + A
    W = np.dot(A, inv(D))
    return W


def GD(G, S_0, L):
    W = get_W(G)
    S_c = S_0
    S_c_r = S_0
    for i in range(0, L):
        S_L = (1 - alpha) * S_0 + alpha * (W @ S_c)
        S_L_R = (W @ S_c_r )
        S_c = S_L
        S_c_r = S_L_R
    return S_L, S_L_R



def get_W_spicy(G):
    ### get propagation matrix ###
    A = nx.to_scipy_sparse_matrix(G, format="csr")
    n, m = A.shape
    diags = 1.0 / A.sum(axis=1)
    D = sp.sparse.spdiags(diags.flatten(), [0], m, n, format="csr")
    W = D * A
    return W


def GD_spicy(G, S_0, L):
    W = get_W_spicy(G)
    S_c = S_0
    S_c_r = S_0
    for i in range(0, L):
        S_L = (1 - alpha) * S_0 + alpha * (S_c * W)
        S_L_R = (S_c_r * W)
        S_c = S_L
        S_c_r = S_L_R
    return S_L, S_L_R



#edge_list = [(1, 9), (9, 2), (1, 10), (10, 3), (2, 4), (2, 5), (3, 6), (2, 3), (1, 7), (7, 2), (1, 8), (8, 2)]
edge_list = [(1, 9), (9, 2), (1, 10), (10, 11), (2, 4), (2, 5), (3, 6), (2, 3), (1, 7), (7, 2), (1, 8), (8, 2), (6, 11), (5, 12),(4, 13), (13, 15), (11, 14), (14, 16)]

G = nx.Graph(edge_list)
node_list = list((G.nodes))
node_cnt = G.number_of_nodes()

alpha = 0.95
max_L = 6
l1 = 4
l2 = 2
k = 5

root = 1
W = get_W(G)
W_spicy = get_W_spicy(G)

root_idx = node_list.index(root)
S0 = np.zeros(node_cnt)
S0[root_idx] = 1


#### Validation of Eq. 6, stage decomposition
print("\n\n########################################")
print("#### Validation of stage decomposition")
print("########################################")
########### non sparse ##########
print("Non Sparse Matrix")
## global diffusion
GD_L_S0, _ = GD(G, S0, max_L)
print("== GD_L_S0:")
print(np.round(GD_L_S0, 3))
print("sum: %.2f" % sum(GD_L_S0))

## multi-level diffusion (stage decomposition)
GD_l1_S0, _ = GD(G, S0, l1)
# print("== GD_l1_S0:")
# print(np.round(GD_l1_S0, 3))

W_l1 = W
for i in range(0, l1 - 1):
    W_l1 = W_l1 @ W
SR = W_l1 @ S0
GD_l2_SR, _ = GD(G, SR, l2)
# print("== SR:")
# print(np.round(SR, 3))

ML_GD = GD_l1_S0 + alpha ** l1 * GD_l2_SR - alpha ** l1 * SR
print("== ML_GD:")
print(np.round(ML_GD, 3))

########### sparse ##########
print("\nSparse Matrix")
## global diffusion
GD_L_S0, _ = GD_spicy(G, S0, max_L)
print("== GD_L_S0:")
print(np.round(GD_L_S0, 3))
print("sum: %.2f" % sum(GD_L_S0))

## multi-level diffusion (stage decomposition)
GD_l1_S0, _ = GD_spicy(G, S0, l1)
W_l1 = W_spicy
for i in range(0, l1 - 1):
    W_l1 = W_l1 * W_spicy
SR = S0 * W_l1
GD_l2_SR, _ = GD(G, SR, l2)

ML_GD = GD_l1_S0 + alpha ** l1 * GD_l2_SR - alpha ** l1 * SR
print("== ML_GD:")
print(np.round(ML_GD, 3))



def set_S_0(g, root, root_score):
    node_list = list((g.nodes))
    node_cnt = g.number_of_nodes()
    S_0 = np.zeros(node_cnt)
    root_idx = node_list.index(root)
    S_0[root_idx] = root_score
    return S_0
    

def collect_next_stage_nodes(scores, g):
    ns_node_with_score = []
    for idx in range(0, len(scores)):
        if scores[idx] == 0:
            continue
        s_r = np.zeros(g.number_of_nodes())
        s_r[idx] = scores[idx]
        ns_node_with_score.append(s_r)
    return ns_node_with_score


#### Validation of Eq. 9, linear decomposition
print("\n\n########################################")
print("#### Validation of linear decomposition")
print("########################################")
scores_G = np.zeros(node_cnt)
root = 1

######### First Level ####################
print("-- First level")
S_0 = set_S_0(G, root, 1)
scores_l1, scores_l1_r = GD(G, S_0, l1)

print("score_l1")
print(np.round(scores_l1, 3))

print("score_l1_r")
print(np.round(scores_l1_r, 3))

scores_G += scores_l1

# Substract scores_l1_r from scores_G
scores_G = scores_G - scores_l1_r * (alpha ** l1)

######### Second Level ####################
print("-- Second level")
ns_nodes = collect_next_stage_nodes(scores_l1_r, G)

print("-- Total next-stage nodes: %d" % len(ns_nodes))

for s_r in ns_nodes:
    scores_l2, scores_l2_r = GD(G, s_r, l2)
    
    # Integrate scores_l2 into scores_G
    scores_G += scores_l2 * (alpha ** l1)
    print(np.round(scores_G, 3))

print("-- Integrated Result of scores_G")
print(np.round(scores_G, 3))
print("sum: %.2f" % sum(scores_G))