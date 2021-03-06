function [mps,Vmat,para,results,op] = minimizeE(op,para)
randn('state', 0)
L=para.L;
M = size(op.h2term,1);

if para.resume==1 && para.savedexist==1
    [Vmat,mps,loop,para,results,op]=loadsaved(para);
else
    loop=1;
    Vmat = createrandomVmat(para);
    mps = createrandommps(para);
    %Preassign space for the results structure.
    results=initresults(para);
end

para=gennonzeroindex(mps,Vmat,para);
para

[mps,Vmat,para] = prepare(mps,Vmat,para);
% storage-initialization
[op] = initstorage(mps, Vmat, op,para);

%The relative change of d_opt and D, 1 means 100%.
para.d_opt_change=1;
para.D_change=1;

while loop<=para.loopmax;
    fprintf('\nloop = %d\n',loop);
    para.loop=loop;
    results.Evalues = [];
    results.flowdiag{loop} = [];
    % ********* cycle 1: j ? j + 1 (from 1 to L - 1)*********
    for j = 1:L
        fprintf('%g-', j); para.sweepto='r';
        op=gen_sitej_op(op,para,j,results.leftge,'lr');
        [Aj,Vmat,results,para,op]=optimizesite(mps,Vmat,op,para,results,j);
        if j~=L
            [mps{j}, U, para,results] = prepare_onesite(Aj, 'lr',para,j,results);
            mps{j+1} = contracttensors(U,2,2,mps{j+1},3,1);
        else
            mps{j}=Aj;
        end
        op=updateop(op,mps,Vmat,j,para);
	Hleft=op.Hlrstorage{j+1};
	eigvalues=sort(eig((Hleft'+Hleft)/2));
	results.leftge(j+1)=eigvalues(1);
        results.Evalues = [results.Evalues, results.E];
    end
    fprintf('\nE = %.10g\t', results.E);
    results.Eerror(loop)=std(results.Evalues)/abs(mean(results.Evalues));
    fprintf('E_error =  %.16g\t',results.Eerror(loop));
    %Calculate the relative change of Vmat von Neumann entropy as one criteria for convergence check 
    vNEdiff=(results.Vmat_vNE(2:end)-results.lastVmat_vNE(2:end))./results.Vmat_vNE(2:end);
    vNEdiff=abs(vNEdiff)
    fprintf('para.shift = \n'); disp(para.shift); 
    results.vNEdiff=vNEdiff;
    results.lastVmat_vNE=results.Vmat_vNE;
    para=trustsite(para,results);
    fprintf('precise_sites k <= %d\t',para.precisesite);
    fprintf('trustable_sites k <= %d\t',para.trustsite(loop));
    
    if para.dimlock==0 && para.trustsite(end)>3 && mod(loop,2)==0%&& para.trustsite(end)/para.precisesite>0.6 && sqrt(var(para.trustsite(end-2:end)))/mean(para.trustsite(end-2:end))<0.1 %The trust site has not been improved during the last 2 sweeps
         %%Expand or Truncate D and d_opt
         para.adjust=1;
         [op,para,results,mps,Vmat]=adjustdopt(op,para,results,mps,Vmat);
         [mps,Vmat,para] = rightnormA(mps,Vmat,para,results);
         %para.trustsite(loop)=0;
         fprintf('d_opt = ');
         disp(para.d_opt);
         fprintf('para.D = ');
         disp(para.D);
     else
        para.adjust=0;
        [mps,Vmat] = rightnormA(mps,Vmat,para,results);
    end
    [op] = initstorage(mps, Vmat, op,para);
   
    fprintf('d_opt_change=%g\t',para.d_opt_change);
    fprintf('D_change=%g\t',para.D_change);
    if para.d_opt_change<0.01 && para.D_change<0.01
      para.dimlock=1;
    end

    results.maxVmatsv=max(cellfun(@(x) x(end), results.Vmat_sv(2:para.trustsite(end))));fprintf('maxVmatsv=%g\t',results.maxVmatsv);
    results.maxAmatsv=max(cellfun(@(x) x(end), results.Amat_sv(2:para.trustsite(end))));fprintf('maxAmatsv=%g\n',results.maxAmatsv);
    %if para.trustsite(loop)>=para.L-2 && max(vNEdiff)<1e-3 && results.maxVmatsv<para.svmintol && results.maxAmatsv<para.svmintol
    if results.Eerror(end)<para.precision %&& para.trustsite(end)>para.L-5
    break;
    end

    %if para.trustsite(end)>para.L-10 && results.maxVmatsv<para.svmaxtol && results.maxAmatsv<para.svmaxtol
%	    break;
%    end
    %Save only every 10 sweeps to save time. (compare to save every step)
    if mod(loop,10)==0
    save(para.filename,'para','Vmat','mps','results','op');
    end
    loop=loop+1;
end
end
