unit Delphi_Class_Declare;

type
  TSigType = class (TObject)
  private
    FName: string; 
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
    Props: TList; //List of type fields
    Children: TList; //list of type children
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
    function FindTypeInTree: Boolean; 
    function CheckTableExist: Boolean; 
    procedure LoadChildren;
    procedure ShowChildren(TV: TfcTreeView);
    procedure ShowFields;
    procedure DeleteChildren;
    function CheckTypeNameEncoding: Boolean;
    function AllowMoveDrop(DropTarget: TSigType): Boolean;
    procedure LoadSignals;
    procedure ShowSignals(FillStartCol: Integer);
    function CheckFieldExists(FieldName: string): Boolean; //check if the field exists in the current type
    procedure ShowSigTableFields(FillStartCol: Integer); //show the headline of the main table
    procedure ShowSigPropsTableFields; //show personal fields of the current type
    procedure ShowSigPropsTableSignals(SigRow: Integer); //show signal fields in the right table (if signal wasnt selected in the leaf-type)
    procedure cbbSelectTypeFill;
    function GetNotEmptyList: TStringList;
    function NotEmptyListCheck: Boolean; //if any cell, which has to be filled by the criterion NOT NULL, is not filled + check if type is indicated
  end;


interface

implementation

end.
 
