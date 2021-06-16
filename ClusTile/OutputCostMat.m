%本程序 用于输出 需要的C矩阵，前提是CostEstimation程序运行完毕，切块程序运行完毕 StartRow 下表从0开始
clear all;
close all;
clc;
vs = 1;
ve = 1;

H = 15;
W = 30;

for videoid = VideoIndex
    obj = VideoReader(['E:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\',sprintf('%03d',videoid),'.mp4']);
    Height = obj.Height;
    Width = obj.Width;
    
    for seconds = SecondIndex
        %try
            ['当前秒数：',num2str(seconds)]
            H = 15;
            W = 30;
            frameStart = (seconds-1)*30+1;
            MotionVector = load(['E:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\out_',sprintf('%d',videoid),'_XX30_0.mp4',num2str(frameStart),'.txt']);
            Gap_Height = floor(Height / H);
            Gap_Width  = floor(Width / W);
       
            tic
            src_H = MotionVector(:,6); src_W = MotionVector(:,5); dst_H = MotionVector(:,8); dst_W = MotionVector(:,7);
            
            for i = 1:H
                src_H(src_H>=(i-1)*Gap_Height+1 & src_H<= i*Gap_Height) = i; %下标从1开始
                dst_H(dst_H>=(i-1)*Gap_Height+1 & dst_H<= i*Gap_Height) = i;
            end
            
            for j = 1:W
                src_W(src_W>=(j-1)*Gap_Width+1 & src_W<= j*Gap_Width) = j;
                dst_W(dst_W>=(j-1)*Gap_Width+1 & dst_W<= j*Gap_Width) = j;
            end
            MotionVector(:,6) = src_H; MotionVector(:,5) = src_W; MotionVector(:,8) = dst_H; MotionVector(:,7) = dst_W;
            src_H = gpuArray(single(src_H));
            src_W = gpuArray(single(src_W));
            dst_W = gpuArray(single(dst_W));
            dst_H = gpuArray(single(dst_H));
            for c = 0:5
                %try
                    filename = ['OutputBNM/' , num2str(videoid) , '/' , num2str(seconds-1) , '/' , num2str(c) , '.mat'];
                    data  = load(filename);
                    M = uint8(data.M);
                    B = uint8(data.B);
                    Extra = uint8(data.Extra);
                    N = uint8(data.N);
                    StartRow = Extra(1);   %下表从0开始
                    EndRow = Extra(2);
                    StartCol = Extra(3);
                    EndCol = Extra(4);
                    

                    % 计算整个视频全编成一块的码率-----------------------------------------------------------------------------------
                    fname_origin = ['E:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(0),'_',num2str(0),'_',num2str(double(H-1+1)*Gap_Height),'_',num2str(double(W-1+1)*Gap_Width),'.mp4'];
                    fid = fopen(fname_origin);
                    fseek(fid,0,'eof');
                    fsize = ftell(fid);
                    fclose(fid);
                    Sorigin =  fsize/(1024);
                    Sorigin = Sorigin*8;
                    Stotal = 0;
                    
                    for r = 1:H
                        for co = 1:W
                            fname_i = ['E:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str((r-1)*Gap_Height),'_',num2str((co-1)*Gap_Width),'_',num2str((r-r+1)*Gap_Height),'_',num2str((co-co+1)*Gap_Width),'.mp4'];
                            fid = fopen(fname_i);
                            fseek(fid,0,'eof');
                            fsize = ftell(fid);
                            fclose(fid);
                            fsize = fsize /1024;
                            fsize = fsize*8;
                            Stotal =  Stotal + fsize;
                        end
                    end
                    
                    temp_Relocated = (dst_H>=1) & (dst_H<=H) & (dst_W>=1) & (dst_W<=W) & (dst_H ~= src_H | dst_W ~= src_W);
                    temp_NonRelocated = (dst_H>=1) & (dst_H<=H) & (dst_W>=1) & (dst_W<=W) & (dst_H == src_H & dst_W == src_W);
                    MotionVectorCount  = sum(temp_Relocated(:));
                    NonLocatedMotionVector = sum(temp_NonRelocated(:));
                    o = single(Stotal - Sorigin) / single(MotionVectorCount);
                    % 计算整个视频全编成一块的码率-----------------------------------------------------------------------------------
                    
                    %需要输出每一个类别的总和码率，跨域motionVector，非跨域motionVector,整体降价比，块数n
                    ttt = 0;
                    
                    for sR = StartRow:EndRow
                        for eR = sR:EndRow
                            for sC = StartCol:EndCol
                                for eC = sC:EndCol
                                    n = (eR - sR +1) * (eC -sC + 1);
                                    if (n<4)
                                        continue
                                    end
                                    ttt = ttt +1;
                                end
                            end
                        end
                    end
                    
                    result  = gpuArray(single(zeros(ttt,11)));
                    BandWidth  = single(zeros(H, W));
                    for r = StartRow:EndRow
                        for co = StartCol:EndCol
                            fname_i = ['E:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'/',num2str(videoid),'_',num2str(seconds-1),'_',num2str(double(r)*Gap_Height),'_',num2str(double(mod(co,30))*Gap_Width),'_',num2str(double(r-r+1)*Gap_Height),'_',num2str(double(co-co+1)*Gap_Width),'.mp4'];
                            fid = fopen(fname_i);
                            fseek(fid,0,'eof');
                            fsize = ftell(fid);
                            fclose(fid);
                            fsize = fsize /1024;
                            fsize = fsize * 8;
                            BandWidth(r+1,mod(co,W)+1) = fsize;
                        end
                    end
               
                    ttt = 0;
                    for sR = StartRow:EndRow
                        for eR = sR:EndRow
                            for sC = StartCol:EndCol
                                for eC = sC:EndCol
                                    n = (eR - sR +1) * (eC -sC + 1);
                                    if (n<4)
                                        continue
                                    end
                                    ttt = ttt +1;
                                    fsize = 99999999;
                                    %求真实码率
                                    try
                                        if (eC<30)
                                            temp=[double(sR)*Gap_Height,double(sC)*Gap_Width,double(eR-sR+1)*Gap_Height,double(eC-sC+1)*Gap_Width];
                                            fname_i = ['E:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'.mp4'];
                                            fid = fopen(fname_i);
                                            fseek(fid,0,'eof');
                                            fsize = ftell(fid);
                                            fclose(fid);
                                            fsize = fsize /1024;
                                            fsize = fsize * 8;
                                        else
                                            if(sC>=30)
                                                temp=[double(sR)*Gap_Height,double(sC-30)*Gap_Width,double(eR-sR+1)*Gap_Height,double(eC-sC+1)*Gap_Width];
                                                fname_i = ['E:\comparing-trajectory-clustering-methods-master\comparing-trajectory-clustering-methods-master\CostEstimation\video\TestData\',num2str(videoid),'\',num2str(videoid),'_',num2str(seconds-1),'_',num2str(temp(1)),'_',num2str(temp(2)),'_',num2str(temp(3)),'_',num2str(temp(4)),'.mp4'];
                                                fid = fopen(fname_i);
                                                fseek(fid,0,'eof');
                                                fsize = ftell(fid);
                                                fclose(fid);
                                                fsize = fsize /1024;
                                                fsize = fsize * 8;
                                            end
                                        end
                                    catch
                                        fsize =99999999;
                                    end
                                    Stotal =  sum(sum(BandWidth(sR+1:eR+1,mod(sC:eC,W)+1)));
                                    Smin  = min(min(BandWidth(sR+1:eR+1,mod(sC:eC,W)+1)));
                                    if eC<H
                                        temp_middle = (dst_H>=(sR+1)) & (dst_H<=(eR+1)) & (dst_W>=(sC+1)) & (dst_W<=(eC+1));
                                    else
                                        temp_middle = (dst_H>=(sR+1)) & (dst_H<=(eR+1)) & (((dst_W>=(sC+1)) & (dst_W<=H)) |((dst_W>=1) & (dst_W<=mod(eC,H)+1)));
                                    end
                                    temp_middle2 = (dst_H ~= src_H) | (dst_W ~= src_W);
                                    temp_Relocated = temp_middle & temp_middle2;
                                    temp_NonRelocated = temp_middle & ~temp_middle2;
                                    ri = sum(temp_Relocated);
                                    mt = sum(temp_NonRelocated);
 
                                    result(ttt,:) = [single(sR+1),single(eR+1),single(sC+1),single(eC+1),single(Stotal), single(ri) ,single(mt), single(o), single(n), single(Smin), single(fsize)];
                                    
                                end
                            end
                        end
                    end
                    
                    result = gather(result);
                    mkdir(['OutputBNM_Xls/' , num2str(videoid) , '/' , num2str(seconds-1) , '/' , num2str(c)])
                    dlmwrite(['OutputBNM_Xls/' , num2str(videoid) , '/' , num2str(seconds-1) , '/' , num2str(c) , '/C_Input.txt'], result,' ')
%                 catch
%                     continue
%                 end
            end
%         catch
%             continue
%         end
    end
end