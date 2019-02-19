function oclSaveToJSON(tensor,path,name,varargin)
  % toJSON(self,path,name,opt)
  if nargin==1
    path = fullfile(getenv('OPENOCL_WORK'),[datestr(now,'yyyymmddHHMM'),'var.json']);
  end
  if nargin<=2
    name = 'var';
  end
  s = oclToStruct(tensor);
  savejson(name,s,path);
  disp(['json saved to ', path]);
end