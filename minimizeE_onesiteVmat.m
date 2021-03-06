% ******************** one-site optimvzization *********************** 
function [B, E] = minimizeE_onesiteVmat(op, A, Blaststep,para)
% A is the local matrix 
% B is the optimized local optimal phonon basis transform matrix
tol=para.eigs_tol;
M = size(op.h2j, 1); 
[Dblast,dlast]=size(Blaststep);

op.HlOPB = contracttensors(op.Hleft,2,2,A,3,1);
op.HlOPB = contracttensors(conj(A),3,[1,2],op.HlOPB,3,[1,2]);

op.HrOPB = contracttensors(A,3,2,op.Hright,2,2);
op.HrOPB = contracttensors(conj(A),3,[1,2],op.HrOPB,3,[1,3]);

op.OpleftOPB= cell(M,1);
op.OprightOPB= cell(M,1);

for m=1:M
op.OpleftOPB{m}= contracttensors(op.Opleft{m}, 2,2, A,3,1);
op.OpleftOPB{m}= contracttensors(conj(A),3,[1,2],op.OpleftOPB{m},3,[1,2]);

op.OprightOPB{m} = contracttensors(A,3,2,op.Opright{m},2,2);
op.OprightOPB{m} = contracttensors(conj(A),3,[1,2],op.OprightOPB{m},3,[1,3]);
end


d = size(op.HlOPB, 1); 
Db = size(op.h2j{1,1}, 1); 


% projection on orthogonal subspace 
%if ~isempty(P), Heff = P' * Heff * P; end 

% optimization 
opts.disp = 0;
opts.tol = tol;
%opts.p=12;
opts.issym =1;
sigma='sa';
if para.complex==1
    opts.isreal = false;
    sigma='sr';
end
assert(Db*d == Dblast*dlast);

if para.parity~='n'
    opts.v0=vertcat(reshape(Blaststep(1:Db/2,1:d/2),Db*d/4,1),reshape(Blaststep(Db/2+1:end,d/2+1:end),Db*d/4,1));
    [Bvec, E]=eigs(@(x) HmultVmat(x, op, Db, d, M, para.parity), Db*d/2,1,sigma,opts);
    B = zeros(Db, d);
    B(1:Db/2,1:d/2)=reshape(Bvec(1:Db*d/4),Db/2,d/2);
    B(Db/2+1:end,d/2+1:end)=reshape(Bvec(Db*d/4+1:end),Db/2,d/2);
else
    opts.v0=reshape(Blaststep,Db*d,1);
    [Bvec, E]=eigs(@(x) HmultVmat(x, op, Db,d, M,para.parity), Db*d,1,sigma,opts);
    B = reshape(Bvec, [Db, d]);
end

end