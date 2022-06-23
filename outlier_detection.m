function [r,a,history] = robustST_stream(x_Omega,W_Omega,OPTS)

if isfield(OPTS,'RHO'),
    rho = OPTS.RHO;
else
    rho = 1.5;
end
if isfield(OPTS,'Alpha'),
    alpha = OPTS.Alpha;
else
    alpha = 1.7;
end
if isfield(OPTS,'MAX_ITER'),
    MAX_ITER = OPTS.MAX_ITER;
else
    MAX_ITER = 500;
end
if isfield(OPTS,'method'),
    method = OPTS.method;
else
    method = 'ADMM';
end

ABSTOL   = 1e-5;
RELTOL   = 1e-3;
%% ADMM for finding a(t), s(t)
[m, n] = size(W_Omega);
% % % For update a(t)
q = randn(m,1);
a = randn(n,1);
% % For update s(t)
u = randn(m,1);
r = randn(m,1);
v = zeros(m,1);

if strcmp(method,'ADMM')
    a_re = W_Omega.' * x_Omega;
    x_re = zeros(m,1);
 
    [L U] = factor(W_Omega,rho);
    for k = 1 : MAX_ITER
        u_old = u;
        u = 1/(rho+1)  * ( x_Omega - x_re  - rho*(r - v) );
        rold = r;
        r = shrinkage(u + v, 1/rho);
        v = v + (u - r);
        
        a_tem = a_re + W_Omega' * (q - r);
        a = U \ (L \ a_tem);
        x_re =  W_Omega*a;
        tmp = x_re - x_Omega + r;
        q_old = q;
        q = 1/(1 + 1/rho)*tmp + 1/(1 + rho)*shrinkage(tmp, 1 + 1/rho);
        
        history.s_norm(k)  = norm(-rho*(r - rold));
        history.eps_dual(k)= sqrt(n)*ABSTOL + RELTOL*norm(rho*v);
        history.u_norm(k)  = norm(u - u_old);
        history.er_norm(k) = norm(q - q_old);
        if history.s_norm(k) < history.eps_dual(k)
            % fprintf(' out %d \n',k)
            break;
        end
    end
else %
    w = zeros(n,1);
    r = zeros(m,1);
    q = zeros(m,1);
    mu = 1.25/norm(x_Omega);
    P = (W_Omega'*W_Omega) \ (W_Omega');
    for k = 1:MAX_ITER
        w = P * (x_Omega -r - q/mu);
        rold = r;
        x_re = W_Omega*w;
        r = shrinkage(x_Omega - x_re - q/mu, 1/mu);
        v = x_re - x_Omega + r;
        q = q + mu * v;
        mu = rho * mu;
        history.s_norm(k)  = norm(-rho*(r - rold));
        history.eps_dual(k)= sqrt(n)*ABSTOL + RELTOL*norm(rho*v);
        if (norm(v) < RELTOL) break; end
    end
end
r(abs(r)< 1) = 0;
end
function y = shrinkage(a, alpha)
y = max(0, a-alpha) - max(0, -a-alpha);
end



