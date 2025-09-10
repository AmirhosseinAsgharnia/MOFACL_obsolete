function critic = normalizer (critic)

num_of_objectives = size(critic , 2);

for i = 1 : num_of_objectives

    critic(: , i) = (critic(: , i) - min(critic(: , i))) /...
        (max(critic(: , i)) - min(critic(: , i)));

end
