clear; clc

R = 0.5;
A=0;
gamma = 0.9;
for i=0:200
    A = A + R*gamma^i;
end