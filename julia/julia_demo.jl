#!/usr/bin/env julia

using LinearAlgebra
using Statistics

# Simple array operations
numbers = 1:100
println("Sum of 1 to 100: ", sum(numbers))
println("Mean of 1 to 100: ", mean(numbers))

# Matrix operations
A = [1.0 2.0 3.0;
     4.0 5.0 6.0;
     7.0 8.0 9.0]

B = [9.0 8.0 7.0;
     6.0 5.0 4.0;
     3.0 2.0 1.0]

C = A * B

println("\nMatrix A:")
display(A)

println("\n\nMatrix B:")
display(B)

println("\n\nA * B:")
display(C)

println("\n\nDeterminant of A: ", det(A))
println("Trace of A: ", tr(A))
