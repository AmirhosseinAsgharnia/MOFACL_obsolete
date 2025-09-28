function K = kronSum(A,B)
    % Kronecker sum of square matrices A (m x m) and B (n x n)
    [m, ~] = size(A);
    [n, ~] = size(B);
    K = kron(A, eye(n)) + kron(eye(m), B);
end