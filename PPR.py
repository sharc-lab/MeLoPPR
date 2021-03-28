import numpy as np
from numpy.linalg import inv
import networkx as nx
import scipy as sp
import matplotlib.pyplot as plt
import re
from random import sample 
import time
import tracemalloc
import json

def get_propagation_matrix(G):
    ### get propagation matrix ###
    A = nx.to_scipy_sparse_matrix(G, format="csr")
    n, m = A.shape
    diags = 1.0 / A.sum(axis=1)
    D = sp.sparse.spdiags(diags.flatten(), [0], m, n, format="csr")
    W = D * A
    return W

def Graph_Diffusion(G, S_0, L):
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


def global_score_integration(lengh_g, scores_global, scores_sub_graph, coeff):
    for s in scores_sub_graph:
        nd_idx = s
        nd_score = scores_sub_graph[nd_idx]
        if nd_idx in scores_global:
            scores_global[nd_idx] += coeff * nd_score
        elif (nd_idx not in scores_global) and (len(scores_global) < lengh_g):
            scores_global[nd_idx] = coeff * nd_score
    scores_global = dict(sorted(scores_global.items(), key=lambda item: item[1], reverse = True))


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
    list_a = list(n for n in list(sorted(list_a.items(), key=lambda item: item[1], reverse=True )[:k]) if n[1] > 0.0001)
    list_b = list(n for n in list(sorted(list_b.items(), key=lambda item: item[1], reverse=True )[:k]) if n[1] > 0.0001)
    
    list_a = set(dict(list_a).keys())
    list_b = set(dict(list_b).keys())

    return 1.0 * len(list_a & list_b) / max(len(list_a), len(list_b))




def build_graph(graph_name):
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



######### MeLoPPR parameters #######
alpha = 0.95
max_L = 6
l1 = 3
l2 = 3
k = 100
scale = 100.0  # inital score scaling factor
total_samples = 1000
ns_max = -1 # -1 to compute all next-stage nodes; otherwise specify a max node count
c = 10 # store c * k global scores to reduce memory requirement


# all_results_prec_time = {}

path = './'
# datasets = ['citeseer_adj', 'cora_adj', 'com-amazon.ungraph', 'pubmed_adj', 'com-dblp.ungraph', 'com-youtube.ungraph']
datasets = ['citeseer_adj']
for dataset in datasets:
    # all_results_prec_time[dataset] = {}

    G = build_graph(path + dataset + '.txt')
    roots = sample(list(G.nodes), total_samples)
    sample_cnt = 0
    for root in roots:
        # all_results_prec_time[dataset][root] = {}
        sample_cnt += 1
        print("\n\n===================================")
        print("== %s : ROOT (%d / %d) %s" % (dataset, sample_cnt, total_samples, root))
        print("===================================")

        ################### Global ###################################
        print("#### Global PPR ####")
        # tracemalloc.start()
        # global_GD_t1 = time.time()
        # global_BFS_t1 = time.time()
        G_l = G.subgraph(list(nx.bfs_tree(G, source = (root), depth_limit = max_L)))
        # global_BFS_t2 = time.time()

        S_0 = set_S_0(G_l, root, 1 * scale)
        scores_org, _ = Graph_Diffusion(G_l, S_0, max_L)
        # global_GD_t2 = time.time()
        # glob_current, glob_peak = tracemalloc.get_traced_memory()
        # tracemalloc.stop()
        # tracemalloc.clear_traces()

        # global_BFS_time = (global_BFS_t2 - global_BFS_t1) * 1000
        # global_GD_time = (global_GD_t2 - global_GD_t1) * 1000 # include BFS time
        # print("global_BFS_time: %.3f (ms)" % global_BFS_time)
        # print("global_GD_time: %.3f (ms)" % global_GD_time)
        # print("global_GD_memory: current: %.3f (MB), peak: %.3f (MB)" % (glob_current / 10**6, glob_peak / 10**6 ))
        # all_results_prec_time[dataset][root]['global_BFS_time'] = global_BFS_time
        # all_results_prec_time[dataset][root]['global_GD_time'] = global_GD_time
        # all_results_memory[dataset][root]['global_GD_memory_curr'] = glob_current / 10**6
        # all_results_memory[dataset][root]['global_GD_memory_peak'] = glob_peak / 10**6

        #print("Global Results")
        #show_scores(scores_org, k)
                    
                    
        ################### Multi-level ##############################
        print("\n#### MeLo PPR ####")
        # tracemalloc.start()
        # ML_GD_t1 = time.time()
        # ML_BFS_time = 0

        ######### First Level ####################\
        #print("-- First level")
        G_sub_l1 = G.subgraph(list(nx.bfs_tree(G, source = (root), depth_limit = l1)))

        S_0 = set_S_0(G_sub_l1, root, 1 * scale)
        scores_l1, scores_l1_r = Graph_Diffusion(G_sub_l1, S_0, l1)

        # Integrate scores_l1 into scores_G
        scores_G = {}
        global_score_integration(c*k, scores_G, scores_l1, 1)
        prec = top_k_precision( scores_org, scores_G, k )
        #show_scores(scores_G, k)
        #print("prec: %.3f" % top_k_precision( scores_org, scores_G, k ))

        # Substract scores_l1_r from scores_G
        global_score_integration(c*k, scores_G, scores_l1_r, -1 * (alpha ** l1))


        # ML_GD_t2 = time.time()
        # ML_GD_time = (ML_GD_t2 - ML_GD_t1) * 1000 # include BFS time

        # all_results_prec_time[dataset][root][0] = {}
        # all_results_prec_time[dataset][root][0]['Precision'] = prec
        # all_results_prec_time[dataset][root][0]['ML_BFS_time'] = ML_BFS_time
        # all_results_prec_time[dataset][root][0]['ML_GD_time'] = ML_GD_time

        ######### Second Level ####################
        #print("-- Second level")
        ns_nodes = collect_next_stage_nodes(scores = scores_l1_r)
        ns_node_max = len(ns_nodes) if ns_max == -1 else min(len(ns_nodes), ns_max)
        print("Computing next-stage nodes: %d out of %d to be computed" % (len(ns_nodes), ns_node_max))
        # all_results_prec_time[dataset][root]['nd_max'] = ns_node_max

        for nd_cnt in range(0, ns_node_max):
            ns_node = ns_nodes[nd_cnt][0]
            ns_node_score = ns_nodes[nd_cnt][1]

            # ML_BFS_t1 = time.time()
            G_sub_l2 = G.subgraph(list(nx.bfs_tree(G, source = (ns_node), depth_limit = l2)))  
            # ML_BFS_t2 = time.time()
            # ML_BFS_time += (ML_BFS_t2 - ML_BFS_t1) * 1000

            S_0 = set_S_0(G_sub_l2, ns_node, ns_node_score)
            scores_l2, scores_l2_r = Graph_Diffusion(G_sub_l2, S_0, l2)

            # Integrate scores_l2 into scores_G
            global_score_integration(c*k, scores_G, scores_l2, 1 * (alpha ** l1))
            prec = top_k_precision( scores_org, scores_G, k )
            #show_scores(scores_G, k)

            # ML_GD_t2 = time.time()
            # ML_GD_time = (ML_GD_t2 - ML_GD_t1) * 1000 # include BFS time

            # ML_current, ML_peak = tracemalloc.get_traced_memory()
            # tracemalloc.stop()
            # tracemalloc.clear_traces()

            print("(%d / %d) MeLo Precision: %.3f" % ( nd_cnt + 1, ns_node_max,  prec))
            # print("ML_BFS_time: %.3f (ms)" % ML_BFS_time)
            # print("ML_GD_time: %.3f (ms)" % ML_GD_time)

            # all_results_memory[dataset][root]['ML_GD_memory_curr'] = ML_current / 10**6
            # all_results_memory[dataset][root]['ML_GD_memory_peak'] = ML_peak / 10**6
        
            # all_results_prec_time[dataset][root][nd_cnt+1] = {}
            # all_results_prec_time[dataset][root][nd_cnt+1]['Precision'] = prec
            # all_results_prec_time[dataset][root][nd_cnt+1]['ML_BFS_time'] = ML_BFS_time
            # all_results_prec_time[dataset][root][nd_cnt+1]['ML_GD_time'] = ML_GD_time

        # print("\n=== Compare MeloPPR with global PPR ===")
        # print("-- MeLoPPR Final Results:")
        # scores_G = dict(sorted(scores_G.items(), key=lambda item: item[1], reverse = True))
        # show_scores(scores_G, k)

        # print("-- Global PPR Results:")
        # show_scores(scores_org, k)

    # f = open('all_results_citeseer.json', 'w+')
    # json.dump(all_results_prec_time, f)
    # f.close()
