% Get video frame
v = VideoReader('../Input/project_video.mp4');

% Output video writer
outputVideo = VideoWriter('../Output/Result.mp4','MPEG-4');
outputVideo.FrameRate = v.FrameRate;
open(outputVideo)

counter=0;

% To find the direction it turns
average_slope_list=[];
figure
while hasFrame(v)
    frame = readFrame(v);
    
    counter = counter+1;
    if counter > 500
        break;
    end
    
    % Filter video
    motion = fspecial('motion', 2, 2);
    frame = imfilter(frame, motion);
    
    imshow(frame)
    
    % Convert to greyscale
    grey=rgb2gray(frame);
    
    % Edge detection
    BW = edge(grey, 'Canny', 0.3);
    
    
    % Mask an image
    x=[220, 1190,725,550];
    y=[665,665,450,450];
    bw = poly2mask(x,y,720,1280);
    BW=BW&bw;
    
    BW = bwmorph(BW,'clean');
    
    % thicken the lines
    se= strel('disk',8);
    BW=imopen(~BW,se);
    BW=~BW;
    
    
    % Clean and make line thin
    BW = bwmorph(BW,'skel',Inf);
    
    
    [H,T,R]=hough(BW);
    
    P= houghpeaks(H,5,'threshold',ceil(0.3*max(H(:))));
    lines = houghlines(BW,T,R,P,'FillGap',5,'MinLength',7);
    
    
    C = imfuse(BW,bw,'blend','Scaling','joint');
    imshow(frame), hold on
    
    max_len=0;
    max_len2=0;
    average_slope=0;
    
    for k = 1:length(lines)
        xy = [lines(k).point1; lines(k).point2];
                
        % Determine the average slope of the line segment on left (top most and
        % bottom most)
        if(lines(k).theta>0)            
            % Determine the endpoints of the longest line segment
            len = norm(lines(k).point1 - lines(k).point2);
            if ( len > max_len)
                 max_len = len;
                 xy_longleft = xy;
            end
        end
        
        % Determine the average slope of the longest line segment on right (top most and
        % bottom most)
        if(lines(k).theta<0)
           % Determine the endpoints of the longest line segment
             len = norm(lines(k).point1 - lines(k).point2);
             if ( len > max_len2)
               max_len2 = len;
               xy_longright = xy;
             end
        end
    end
    
    average_slope = (xy_longleft(1,2)-xy_longleft(2,2))/(xy_longleft(1,1)-xy_longleft(2,1)) + (xy_longright(1,2)-xy_longright(2,2))/(xy_longright(1,1)-xy_longright(2,1));
    average_slope=average_slope/2;
    average_slope_list= [average_slope_list average_slope];
    
    if(numel(average_slope_list)>5)
        average_slope_list=average_slope_list(2:end);
    end

    turn_threshold = (0.13*5);
    if sum(average_slope_list)<-turn_threshold
        text(640,360,"Turning Left")
    elseif sum(average_slope_list)>turn_threshold
        text(640,360,"Turning Right")
    else 
        text(640,360,"Straight")
    end
    
    edge_bottom=700;
    edge_top=470;
    
    left_p1=((edge_bottom-xy_longleft(1,2))*((xy_longleft(2,1)-xy_longleft(1,1))/(xy_longleft(2,2)-xy_longleft(1,2))))+xy_longleft(1,1);
    left_p2=((edge_top-xy_longleft(1,2))*((xy_longleft(2,1)-xy_longleft(1,1))/(xy_longleft(2,2)-xy_longleft(1,2))))+xy_longleft(1,1);
    
    right_p1=((edge_bottom-xy_longright(1,2))*((xy_longright(2,1)-xy_longright(1,1))/(xy_longright(2,2)-xy_longright(1,2))))+xy_longright(1,1);
    right_p2=((edge_top-xy_longright(1,2))*((xy_longright(2,1)-xy_longright(1,1))/(xy_longright(2,2)-xy_longright(1,2))))+xy_longright(1,1);
   
    
    % Plot longest left line
    plot([left_p1,left_p2],[edge_bottom,edge_top],'LineWidth',2,'Color','green');
    
    % Plot longest right line
    plot([right_p1,right_p2],[edge_bottom,edge_top],'LineWidth',2,'Color','green');
    
    filler=fill([left_p1,left_p2,right_p2,right_p1],[edge_bottom,edge_top,edge_top,edge_bottom],'red');
    alpha(filler,.5)
    hold off
    drawnow
    
    % Write to video file
    writeVideo(outputVideo,getframe)
end

% Finalize the video
close(outputVideo)
