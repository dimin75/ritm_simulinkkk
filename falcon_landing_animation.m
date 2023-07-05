function out=falcon_landing_animation(u)
persistent prev_time prev_y 

thrust_dir = u(7);
thrust_force = u(6);
rocket_angle = u(2);
rocket_x = u(3);
rocket_y = u(4);
model_time = u(5);
support_angle = u(1);


thrust_dir = - thrust_dir*(1+randn*0.01);
thrust_force = thrust_force*(1+randn*0.05);
rocket_angle = rocket_angle + pi/2;

if thrust_force<0
    thrust_force=0;
end


hf=4122016;

H=50/2;
W=3.7/2;
L=7;

st=0.01;
rocket=[-H H H -H;
        -W -W W W];    
flame=[0 -0.4*20 -0.6*20 -1*20 -0.6*20 -0.4*20;
       0 1.5 1.2 0 -1.2 -1.5];

flame_sm=[-H -H -H -H -H -H;
           0 0 0 0 0 0];

support_left=[-H -H+1 -H+L
              W W W];       
support_right=[-H -H+1 -H+L
              -W -W -W];       


stop_simulation=0;
score=1000;
if ~ishandle(hf) 
    if model_time==0
        figure(hf)
        set(hf,'NumberTitle','off','Name','Где-то в Тихом океане...')
        uicontrol('style','pushbutton','position',[5 5 50 20],'string','stop','callback',@btn_stop,'BackgroundColor',[106 135 172]/255)
        s=get(hf,'position');
        set(hf,'position',[s(1) s(2) s(3) s(3)*9/16])        
        set(hf,'SizeChangedFcn',@resizer);
        b=[99 129 170]/255;
        a=[20 46 85]/255;
        c=0.5*[51 72 115]/255;
        d=1.2*[143 168 202]/255;        
        q=linspace(0,1,100)';
        colormap([a(1)+(b(1)-a(1))*q a(2)+(b(2)-a(2))*q a(3)+(b(3)-a(3))*q]);
        color1=[a(1)+(b(1)-a(1))*q a(2)+(b(2)-a(2))*q a(3)+(b(3)-a(3))*q];
        color2=[c(1)+(d(1)-c(1))*q c(2)+(d(2)-c(2))*q c(3)+(d(3)-c(3))*q];
        colormap([color1; color2]);
        prev_time=-1;
        prev_y=0;
        % создание элементов сцены
        set(hf,'Color',[106 135 172]/255,'Toolbar','none','Menubar','none')
        handles.axes=axes('position',[0 0 1 1],'XLim',[-500 500],'YLim',[-100 350]);        
        
        patch([-5000 5000 5000 -5000],[-100 -100 170 170],[0 0 100 100],'EdgeColor','none')  % море
        
        
        rectangle('position',[-35 -5 70 10],'FaceColor',[33 56 98]/255,'EdgeColor','none','Curvature',[1 1])
        line([-15 14.5],[-2 2],'Linewidth',0.75,'Color',[15 28 49]/255)
        line([-14.5 15],[2 -2],'Linewidth',0.75,'Color',[15 28 49]/255)
        
        handles.rocket=patch(rocket(1,:),rocket(2,:),[101 101 200 200],'EdgeColor','none');  % ракета                    
        
        handles.flame=patch(flame(1,:)-H,flame(2,:),'w','EdgeColor',[249 208 182]/255);  % пламя
        
        handles.left_support=patch(support_left(1,:)-H,support_left(2,:),[15 28 49]/255,'EdgeColor',[15 28 49]/255);
        handles.right_support=patch(support_right(1,:)-H,support_right(2,:),[15 28 49]/255,'EdgeColor',[15 28 49]/255);
               
        
        axis off

        handles.ylim=[-100 350];
        handles.xlim=[-350 350];
        handles.stop=0;
        handles.text=-1;        
        guidata(gcf,handles)
        resizer
    else
        stop_simulation=1;
        prev_time=inf;
    end
else
    handles=guidata(gcf);
end

if model_time==0            
      figure(hf)
      handles=guidata(gcf);
      if ishandle(handles.text)
          delete(handles.text)
      end
      handles.stop=0;
      guidata(gcf,handles)
      prev_time=-1;            
end

if ~stop_simulation && prev_time+st<model_time
    if handles.stop
        stop_simulation=1;
    else
        % перерисовка сцены       
        c=cos(rocket_angle); s=sin(rocket_angle);
        M=[c -s; s c];
        rr=M*rocket;
        set(handles.rocket,'XData',rr(1,:)+rocket_x,'YData',rr(2,:)+rocket_y);
        
        sup_angle=support_angle*pi/180;
        support_left(1,3)=support_left(1,1)+L*cos(sup_angle);
        support_left(2,3)=support_left(2,1)+L*sin(sup_angle);
        sleft=M*support_left;
        set(handles.left_support,'XData',sleft(1,:)+rocket_x,'YData',sleft(2,:)+rocket_y);

        support_right(1,3)=support_right(1,1)+L*cos(sup_angle);
        support_right(2,3)=support_right(2,1)-L*sin(sup_angle);
        sright=M*support_right;
        set(handles.right_support,'XData',sright(1,:)+rocket_x,'YData',sright(2,:)+rocket_y);
        
        c=cos(thrust_dir); s=sin(thrust_dir);
        fx=thrust_force*flame(1,:);
        fy=flame(2,:);
        
        rf=M*([c -s; s c]*([fx; fy])+flame_sm);
        set(handles.flame,'XData',rf(1,:)+rocket_x,'YData',rf(2,:)+rocket_y);
        drawnow % limitrate
        
        crash=sum((rr(2,:)+rocket_y)<0);
        good_landing=sleft(2,3)+rocket_y<=0 && sright(2,3)+rocket_y<=0;  % посадка, если обе опоры коснулись платформы 
        score=1000+abs(rocket_x);
        if crash || good_landing
            stop_simulation=1;
            p=max(sleft(2,3)+rocket_y, sright(2,3)+rocket_y);
            
            if good_landing
                t1=model_time-(model_time-prev_time)*p/(rocket_y-prev_y);
                if t1>model_time, t1=model_time; end
                if t1<prev_time, t1=prev_time; end
                t2=rocket_x;
                t3=(rocket_y-prev_y)/(model_time-prev_time);
                t4=abs(atan2(sin(rocket_angle-pi/2),cos(rocket_angle-pi/2)))*180/pi;
                score=t1+abs(t2)+abs(t3)+abs(t4);
                str={['Время: ' num2str(t1) ' c'],...
                    ['Отклонение: ' num2str(t2) ' м'],...
                    ['Скорость: ' num2str(t3) ' м/c'],...
                    ['Наклон: ' num2str(t4) ' град'],...
                    '- - - - - - - - - - -',...
                    ['Штрафной балл: ' num2str(score)]};
                color=[1 1 0.6];
            else
                str='Аварийная посадка!';
                color=[1 0 0.2];
            end
            xm=get(handles.axes,'XLim');
            ym=get(handles.axes,'YLim');
            handles.text=text(xm(1)+(xm(2)-xm(1))*0.01,ym(2),str,'Color',color,'VerticalAlignment','top');
            guidata(gcf,handles);            

        end
        
        prev_time=model_time;
        prev_y=rocket_y;
    end
end
out=[stop_simulation score];


function btn_stop(~,~)
handles=guidata(gcf);
handles.stop=true;
guidata(gcf,handles)

function resizer(~,~)
handles=guidata(gcf);
s=get(gcf,'Position');
px=s(3); py=s(4);  % пиксели
mx=handles.xlim(2)-handles.xlim(1);  % метры
my=handles.ylim(2)-handles.ylim(1);  % метры
if mx/px>my/py
    m=mx/px; % мастштаб по x (метров в 1 пикселе)
    limy=[sum(handles.ylim)/2-m*py*0.5 sum(handles.ylim)/2+m*py*0.5];
    if limy(1)<-100
        limy=[-100 m*py-100];
    end
    set(handles.axes,'XLim',handles.xlim,'YLim',limy)
else
    m=my/py; % мастштаб по y    
    set(handles.axes,'XLim',[sum(handles.xlim)/2-m*px*0.5 sum(handles.xlim)/2+m*px*0.5],'YLim',handles.ylim)
end    
if ishandle(handles.text)
    xm=get(handles.axes,'XLim');
    ym=get(handles.axes,'YLim');   
    set(handles.text,'position',[xm(1)+(xm(2)-xm(1))*0.01 ym(2)]);
end

