# k-means-in-Zig
An implementation of k-means clustering algorithm in Zig programming language

## About k-means  
The k-means algorithm is an iterative data clustering algorithm developed by Stuart Lloyd of Bell Labs in the 1950s as a technique for pulse-code modulation.  
The main idea of the algorithm is that at each iteration, based on the existing partitioning, the cluster centers are recalculated, then the objects are divided into clusters according to which of the new centers turned out to be closer to a specific object according to a pre-selected metric. 
#### Input data:
  +  $X=\mathrm{x}_{i=1,j=1}^{n,m}$ — description of objects, where n — number of objects, m — number of attributes;  
  +  $k \in \left \\{1, \ldots, n \right \\}$ — number of clusters.  
#### Output data:   
  +  $Y = \left\\{ y_i|y_i\in\left\\{1,\ldots,k\right\\}, i = \overline{\left(1,n\right)}\right\\}$ — cluster labels.  
#### Advantages of k-means:
  +  Low algorithmic complexity;  
  +  Easy to implement;  
  +  The possibility for effective parallelization;  
  +  The presence of many modifications.  
#### Disadvantages of k-means:   
  +  Sensitivity to initial cluster centers; 
  +  Algorithm k-means poorly separates  closely spaced clusters with a complex structure;  
  +  The need for preliminary determination of the number of clusters.  
### Steps of k-means algorithm  
Step 1. Data preparing (autoscaling): $x_{i,j}=\frac{x_{i,j}-\mathrm{E_{X^{j}}}}{\sigma_{X^{j}}}$;  
Step 2. Set initial cluster centers: $C = \left\\{c_{i}| c_{i} \in ℝ^{m}, i = \overline{\left(1,k\right)} \right\\}$;  
Step 3. Calculate the initial partition: $y_{i} = \arg\min\limits_{j}\rho\left(x_{i},c_{j} \right)$;  
Step 4. Calculate new cluster centers:  
$$l_j=\sum_{i=1}^{n}{\left[y_i\equiv j\right]}$$ $$c_j=\frac{1}{l_j} \sum_{i=1}^{n}{\left[y_i\equiv j\right]\cdot x_i}$$  
Step 5. Calculate a new split: $y_{i} = \arg\min\limits_{j}\rho\left(x_{i},c_{j} \right)$;   
Step 6. Repeat steps 4, 5 until the split changes.  
## Example of usage
```
git clone https://github.com/KlimentLagrangiewicz/k-means-in-Zig
cd ./k-means-in-Zig  
zig build-exe -lc -O ReleaseSafe -freference-trace  ./src/main.zig 
./main ./data_sets/iris result
 ```
