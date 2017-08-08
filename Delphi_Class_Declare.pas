unit Delphi_Class_Declare;

type
  TSigType = class (TObject)
  private
    FName: string; {имя типа}
    FDataType: string;
    FValFldType: string;
    FParent: TSigType;
    FTreeNode: TfcTreeNode;
    procedure SetDataType (DataTypeValue: string);
    procedure SetValFldType (ValFldTypeValue: string);
    procedure SetName (NameValue: string);
    procedure SetTreeNode (TreeNodeValue: TfcTreeNode);
    procedure SetParent(ParentValue: TSigType);
  public
    Props: TList; {набор свойств типа}
    Children: TList; {набор "детей" класса типов}
    Signals: TList;
    property Name: string read FName write SetName;
    property DataType: string read FDataType write SetDataType;
    property ValFldType: string read FValFldType write SetValFldType;
    property Parent: TSigType read FParent write SetParent;
    property TreeNode: TfcTreeNode read FTreeNode write SetTreeNode;
    constructor CreateNew(TypeName,DataType,ValFldType: string; Parent: TSigType);
    constructor CreateLoad;
    destructor Free; reintroduce;
    //procedure Save;
    procedure Load;
    procedure Show;
    procedure Delete;
    procedure AddTable;
    function FindTypeInTree: Boolean; {проверяет, внесен ли текущий тип в дерево}
    function CheckTableExist: Boolean; {проверяет, существует ли таблица}
    procedure LoadChildren;
    procedure ShowChildren(TV: TfcTreeView);
    procedure ShowFields;
    procedure DeleteChildren;
    function CheckTypeNameEncoding: Boolean;
    function AllowMoveDrop(DropTarget: TSigType): Boolean;
    procedure LoadSignals;
    procedure ShowSignals(FillStartCol: Integer);
    function CheckFieldExists(FieldName: string): Boolean; //проверяет, существует ли поле у текущего типа
    procedure ShowSigTableFields(FillStartCol: Integer); //отобразить "шапку" центральной таблицы
    procedure ShowSigPropsTableFields; //отобразить индивидуальные свойства типа
    procedure ShowSigPropsTableSignals(SigRow: Integer); //отобразить поля сигнала в правой таблице(если выбран сигнал в не-листовом типе)
    procedure cbbSelectTypeFill;
    function GetNotEmptyList: TStringList;
    function NotEmptyListCheck: Boolean; //если хоть какая-то ячейка, которая должна быть заполнена по критерию NOT NULL, не заполнена + проверка указания типа
  end;


interface

implementation

end.
 