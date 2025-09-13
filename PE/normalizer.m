function critic = normalizer (critic)

num_of_objectives = size(critic , 2);

for i = 1 : num_of_objectives
    
    max_critic = max(critic(: , i));
    min_critic = min(critic(: , i));

    if max_critic ~= min_critic
        critic(: , i) =...
            (critic(: , i) - min_critic) / (max_critic - min_critic);
    end
    
    S = sum(critic , 2);

    % if sum(S==2) == 1
    %     disp("pause")
    % end
end
