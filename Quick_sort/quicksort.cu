#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#define SIZE 50000
 void printArr( int arr[], int n )
{
    int i;
    for ( i = 0; i < n; ++i )
        printf( "%d ", arr[i] );
}
__device__ int d_size;

__global__ void partition (int *arr, int *arr_l, int *arr_h, int n)
{
    int z = blockIdx.x*blockDim.x+threadIdx.x;
    d_size = 0;
    __syncthreads();
    if (z<n)
      {
        int h = arr_h[z];
        int l = arr_l[z];
        int x = arr[h];
        int i = (l - 1);
        int temp;
        for (int j = l; j <= h- 1; j++)
          {
            if (arr[j] <= x)
              {
                i++;
                temp = arr[i];
                arr[i] = arr[j];
                arr[j] = temp;
              }
          }
        temp = arr[i+1];
        arr[i+1] = arr[h];
        arr[h] = temp;
        int p = (i + 1);
        if (p-1 > l)
          {
            int ind = atomicAdd(&d_size, 1);
            arr_l[ind] = l;
            arr_h[ind] = p-1;  
          }
        if ( p+1 < h )
          {
            int ind = atomicAdd(&d_size, 1);
            arr_l[ind] = p+1;
            arr_h[ind] = h; 
          }
      }
}
 
void quickSortIterative (int arr[], int l, int h)
{
    int lstack[ h - l + 1 ], hstack[ h - l + 1];
 
    int top = -1, *d_d, *d_l, *d_h;
 
    lstack[ ++top ] = l;
    hstack[ top ] = h;

    cudaMalloc(&d_d, (h-l+1)*sizeof(int));
    cudaMemcpy(d_d, arr,(h-l+1)*sizeof(int),cudaMemcpyHostToDevice);

    cudaMalloc(&d_l, (h-l+1)*sizeof(int));
    cudaMemcpy(d_l, lstack,(h-l+1)*sizeof(int),cudaMemcpyHostToDevice);
    cudaMalloc(&d_h, (h-l+1)*sizeof(int));
    cudaMemcpy(d_h, hstack,(h-l+1)*sizeof(int),cudaMemcpyHostToDevice);
    int n_t = 1;
    int n_b = 1;
    int n_i = 1; 
    while ( n_i > 0 )
    {
        partition<<<n_b,n_t>>>( d_d, d_l, d_h, n_i);
        int answer;
        cudaMemcpyFromSymbol(&answer, d_size, sizeof(int), 0, cudaMemcpyDeviceToHost); 
        if (answer < 1024)
          {
            n_t = answer;
          }
        else
          {
            n_t = 1024;
            n_b = answer/n_t + (answer%n_t==0?0:1);
          }
        n_i = answer;
        cudaMemcpy(arr, d_d,(h-l+1)*sizeof(int),cudaMemcpyDeviceToHost);
    }
}
 

 
int main(int argc, char **argv) {

      
       int *arr;
       int numElements; 
    
    FILE *inp1 = fopen(argv[1], "r");
    fscanf(inp1, "%d", &numElements);
    
    printf("\nInput length = %d\n",numElements);
    arr= new int[numElements];
    for(int i = 0; i < numElements; ++i){
	fscanf(inp1, "%d", &arr[i]);
	
    }
    
   /* printf("\nInput\n");    
    for(int i=0;i<numElements;i++){
    	printf("%d ",arr[i]);
    }
*/
    int start_s=clock();
    quickSortIterative( arr, 0, numElements);
    int stop_s=clock();
    
    
  
    
    
    
    FILE *op = fopen(argv[2], "r");
    fscanf(op, "%d", &numElements);
    int *output;
    output=new int[numElements];
    for(int i = 0; i < numElements; ++i){
	fscanf(op, "%d", &output[i]);
    }
    int flag=0;
    printf("\n");
    for(int i=0;i<numElements;i++){
    	if(output[i]!=arr[i+1]){
    		printf("\nSolution wrong Expecting : %d but got : %d\n",output[i],arr[i]);
    		flag=1;
    	}
    }
    if(flag==0){
    printf("\nSolution is Correct !!!\n");
    printf("\nTime :  %f s \n",(stop_s-start_s)/double(CLOCKS_PER_SEC));
    }
    
    fclose(op);
    fclose(inp1);
    
    //printf("\nOutput\n");
    //printArr( arr, numElements);

    return 0;
}
