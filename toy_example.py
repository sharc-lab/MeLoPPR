import numpy as np
from numpy.linalg import inv
import networkx as nx
import scipy as sp
import re
from random import sample 
import sys
import argparse


def get_propagation_matrix(G):
    ### get propagation matrix ###
    A = nx.to_scipy_sparse_matrix(G, format="csr")
    n, m = A.shape
    diags = 1.0 / A.sum(axis=1)
    D = sp.sparse.spdiags(diags.flatten(), [0], m, n, format="csr")
    W = D * A
    return W

def Graph_Diffusion(G, S_0, L, alpha):
    node_list = list((G.nodes))
    W = get_propagation_matrix(G)
    
    S_c = S_0
    S_c_r = S_0
    for i in range(0, L):
        S_L = (1 - alpha) * S_0 + alpha * (S_c * W)
        S_L_R = (S_c_r * W)
        S_c = S_L
        S_c_r = S_L_R

    scores = sort_scores(S_L, node_list)
    scores_r = sort_scores(S_L_R, node_list)
    return scores, scores_r


def sort_scores(S_L, node_list):
    scores = {}
    for n in range(0, len(node_list)):
        pi = S_L[n]
        node_id = node_list[n]
        scores[node_id] = pi
    scores = dict(sorted(scores.items(), key=lambda item: item[1], reverse = True))
    return scores


def collect_next_stage_nodes(scores):
    nodes = list(sorted(scores.items(), key=lambda item: item[1], reverse = True))
    return list(node for node in nodes if node[1] != 0 )



def set_S_0(g, root, root_score):
    node_list = list((g.nodes))
    node_cnt = g.number_of_nodes()
    S_0 = np.zeros(node_cnt)
    root_idx = node_list.index(root)
    S_0[root_idx] = root_score
    return S_0


def global_score_integration(scores_global, scores_sub_graph, coeff):
    for s in scores_sub_graph:
        nd_idx = s
        nd_score = scores_sub_graph[nd_idx]
        scores_global[nd_idx] = (scores_global[nd_idx] + (coeff * nd_score))

def show_scores(scores, top_k = -1):
    if top_k == -1:
        top_k = len(scores)
    for ele in scores:
        if scores[ele] < 0.0001:
            break
        if top_k < 0:
            break
        top_k -= 1
        print("n%s: %.3f " % (str(ele), scores[ele]), end="")
    print("")


def top_k_precision( list_a, list_b, k ):
    list_a = set(dict(sorted(list_a.items(), key=lambda item: item[1], reverse=True )[:k]).keys())
    list_b = set(dict(sorted(list_b.items(), key=lambda item: item[1], reverse=True )[:k]).keys())
    return 1.0 * len(list_a & list_b) / k


def build_graph(graph_name):
    #edge_list = [(1, 9), (9, 2), (1, 10), (10, 3), (2, 4), (2, 5), (3, 6), (2, 3), (1, 7), (7, 2), (1, 8), (8, 2)]
    f = open(graph_name, 'r')
    edge_list = []
    for line in f:
        #print(line)
        u = re.findall(r'\d+', line)[0]
        v = re.findall(r'\d+', line)[1]
        edge_list.append((u, v))

    G = nx.Graph(edge_list)
    node_list_G = list((G.nodes))
    node_cnt_G = G.number_of_nodes()
    degree_sequence = sorted([d for n, d in G.degree()], reverse=True)
    degree_list_G = G.degree()
    d_max = max(degree_sequence)
    d_avg = sum(degree_sequence) / node_cnt_G
    print("Max degree: %d, avg degree: %d" % (d_max, d_avg))

    return G



def main():
    parser = argparse.ArgumentParser(description='Toy example of MeLoPPR')
    parser.add_argument('--path', type=str, default='.', help='the dataset path')
    parser.add_argument('--dataset', type=str, default='cora_adj', help='the dataset name')
    parser.add_argument('--alpha', type=float, default=0.96, help='alpha value')
    parser.add_argument('--max_L', type=int, default=6, help='the total steps of graph diffusion (L=l1+l2)')
    parser.add_argument('--l1', type=int, default=3, help='l1')
    parser.add_argument('--l2', type=int, default=3, help='l2')
    parser.add_argument('--k', type=int, default=20, help='top-k')
    parser.add_argument('--seeds_cnt', type=int, default=10, help='the number of seed nodes to run')
    parser.add_argument('--ns_max', type=int, default=-1, help='the number of next-stage nodes (-1 means all)')

    args = parser.parse_args()

    path = args.path + '/'
    dataset = args.dataset
    G = build_graph(path + dataset + '.txt')


    alpha = args.alpha
    max_L = args.max_L
    l1 = args.l1
    l2 = args.l2
    k = args.k
    total_samples = args.seeds_cnt
    ns_max = args.ns_max
    scale = 1.0

    for root in sample(list(G.nodes), total_samples):
        print("\n\n==============================")
        print("========== ROOT %s =========" % root)
        print("==============================")

        ################### Global ###################################
        G_l = G.subgraph(list(nx.bfs_tree(G, source = (root), depth_limit = max_L)))
        S_0 = set_S_0(G_l, root, 1 * scale)
        scores_org, _ = Graph_Diffusion(G_l, S_0, max_L, alpha)

        print("Global Results")
        show_scores(scores_org, k)
                    
                    
        ################### Multi-level ##############################
        # initialize global score scores_G
        scores_G = {}
        node_list_G = list(G.nodes)
        for n in node_list_G:
            scores_G[n] = 0.0


        ######### First Level ####################
        print("-- First level")
        G_sub_l1 = G.subgraph(list(nx.bfs_tree(G, source = (root), depth_limit = l1)))
        S_0 = set_S_0(G_sub_l1, root, 1 * scale)
        scores_l1, scores_l1_r = Graph_Diffusion(G_sub_l1, S_0, l1, alpha)

        # Integrate scores_l1 into scores_G
        global_score_integration(scores_G, scores_l1, 1)
        scores_G = dict(sorted(scores_G.items(), key=lambda item: item[1], reverse = True))
        #show_scores(scores_G, k)
        print("prec: %.3f" % top_k_precision( scores_org, scores_G, k ))

        # Substract scores_l1_r from scores_G
        global_score_integration(scores_G, scores_l1_r, -1 * (alpha ** l1))

        ######### Second Level ####################
        print("-- Second level")
        ns_nodes = collect_next_stage_nodes(scores = scores_l1_r)
        ns_node_max = len(ns_nodes) if ns_max == -1 else min(len(ns_node), ns_max)
        print("Computing next-stage nodes: %d out of %d to be computed" % (len(ns_nodes), ns_node_max))

        for nd_cnt in range(0, ns_node_max):
            ns_node = ns_nodes[nd_cnt][0]
            ns_node_score = ns_nodes[nd_cnt][1]

            G_sub_l2 = G.subgraph(list(nx.bfs_tree(G, source = (ns_node), depth_limit = l2)))  

            S_0 = set_S_0(G_sub_l2, ns_node, ns_node_score)
            scores_l2, scores_l2_r = Graph_Diffusion(G_sub_l2, S_0, l2, alpha)
            
            # Integrate scores_l2 into scores_G
            global_score_integration(scores_G, scores_l2, 1 * (alpha ** l1))

            scores_G = dict(sorted(scores_G.items(), key=lambda item: item[1], reverse = True))
            print("(%d / %d)" % (nd_cnt + 1, len(ns_nodes)), end=" ")
            #show_scores(scores_G, k)
            print("prec: %.3f" % top_k_precision( scores_org, scores_G, k ))

        print("\n=== Compare MeloPPR with global PPR ===")
        print("-- MeLoPPR Final Results:")
        scores_G = dict(sorted(scores_G.items(), key=lambda item: item[1], reverse = True))
        show_scores(scores_G, k)

        print("-- Global PPR Results:")
        show_scores(scores_org, k)







if __name__ == "__main__":
    main()