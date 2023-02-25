AutoBD Paper
============

This repository contains all code to execute the experiments for the automated boundary detection and summarization study in [this paper](https://arxiv.org/abs/2207.09065). While all results can be reproduced directionally that way, the original results can be downloaded from [here](https://1drv.ms/u/s!AuZALvfcrtYImfl4oKtCgYPFpFCp6g?e=UTdnEV).

All experiments were run with programming language Julia version 1.8.0.

Reproduction (Linux)
---
1. Install Julia (tested on version 1.8.0).
2. Open the Julia console with ```JULIA_COPY_STACKS=1 JULIA_NUM_THREADS=$(nproc) GKSwstype=100 project=. julia``` and enter from the terminal.
3. Type ```include("src/experiments/run.jl")``` and enter.
4. The results and statistics will start accrue in the results directory. Come back in some days.

If you are interested in using, contributing, or learning about AutoBVA, we are happy to discuss - feel free to reach out (find contact details in linked paper above).

MIT License

Copyright (c) 2023 Felix Dobslaw

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
