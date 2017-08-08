unit Delphi_Class_Declare;

type
  TSigType = class (TObject)
  private
    FName: string; {��� ����}
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
    Props: TList; {����� ������� ����}
    Children: TList; {����� "�����" ������ �����}
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
    function FindTypeInTree: Boolean; {���������, ������ �� ������� ��� � ������}
    function CheckTableExist: Boolean; {���������, ���������� �� �������}
    procedure LoadChildren;
    procedure ShowChildren(TV: TfcTreeView);
    procedure ShowFields;
    procedure DeleteChildren;
    function CheckTypeNameEncoding: Boolean;
    function AllowMoveDrop(DropTarget: TSigType): Boolean;
    procedure LoadSignals;
    procedure ShowSignals(FillStartCol: Integer);
    function CheckFieldExists(FieldName: string): Boolean; //���������, ���������� �� ���� � �������� ����
    procedure ShowSigTableFields(FillStartCol: Integer); //���������� "�����" ����������� �������
    procedure ShowSigPropsTableFields; //���������� �������������� �������� ����
    procedure ShowSigPropsTableSignals(SigRow: Integer); //���������� ���� ������� � ������ �������(���� ������ ������ � ��-�������� ����)
    procedure cbbSelectTypeFill;
    function GetNotEmptyList: TStringList;
    function NotEmptyListCheck: Boolean; //���� ���� �����-�� ������, ������� ������ ���� ��������� �� �������� NOT NULL, �� ��������� + �������� �������� ����
  end;


interface

implementation

end.
 