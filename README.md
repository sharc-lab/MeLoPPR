MeLoPPR
=============================================

This repository is the implementation of the paper MELOPPR: Software/Hardware Co-design for Memory-efficientLow-latency Personalized PageRank published at DAC'21.

----------------

Prerequisites
------------------
- Python3 preferred
- Networkx package

------------------

Datasets:
-------------

MeLoPPR is tested on six graphs: citeseer, cora, pubmed, dblp, amazon, and youtube.

This repository contains the first three, and you may download the others from [SNAP](https://snap.stanford.edu/data/)

------------------

Code description
-------------------------
- equation_validation.py: validates the stage decomposition and linear decomposition equations
- toy_example.py: validates the algorithm on the citeseer graph
- PPR.py: include the optimizations discussed in the paper (with memory and CPU time measuring code commented)

------------------

Bugs
----

If you experience bugs, or have suggestions for improvements, please use the
issue tracker to report them.

------------------

Publication
-----------

If this code has been useful to your research, please consider citing us:

**BibTeX:**
```
@inproceedings{meloppr,
  title={MeLoPPR: Software/Hardware Co-design for Memory-efficientLow-latency Personalized PageRank},
  author={Lixiang Li, Yao Chen, Zacharie Zirnheld, Pan Li, and Cong Hao},
  booktitle={2021 58th ACM/IEEE Design Automation Conference (DAC'21)},
  year={2021}
}
```