port module Main exposing (main)

import Browser
import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Json.Decode as JD


port localStorageGetReq : { key : String } -> Cmd msg


port localStorageGetResp : ({ value : String } -> msg) -> Sub msg


port localStorageSet : { key : String, value : String } -> Cmd msg


port localStorageClear : () -> Cmd msg


type alias SourceFile =
    { name : String
    , content : String
    }


type alias Flags =
    { title : String
    , sourceFiles : List SourceFile
    }


type alias Model =
    { title : String
    , sourceFiles : List SourceFile
    , waitingForJs : Bool
    , localStorageFormKey : String
    , localStorageFormValue : String
    }


type Msg
    = UpdLocalStorageFormKey String
    | UpdLocalStorageFormValue String
    | GetFromLocalStorageReq
    | GetFromLocalStorageResp String
    | SetToLocalStorage
    | ClearLocalStorage
    | UpdSourceCode Int String


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        initialState =
            { title = flags.title
            , sourceFiles = flags.sourceFiles
            , waitingForJs = False
            , localStorageFormKey = ""
            , localStorageFormValue = ""
            }
    in
    ( initialState, Cmd.none )


view : Model -> Html Msg
view model =
    H.div [] <|
        [ H.fieldset [ A.disabled model.waitingForJs ]
            [ H.h1 [] [ H.text model.title ]
            , viewLabeledInput "Key" model.localStorageFormKey UpdLocalStorageFormKey
            , viewLabeledInput "Value" model.localStorageFormValue UpdLocalStorageFormValue
            , H.p [ A.class "row" ]
                [ H.div [ A.class "spacer" ] []
                , H.div [ A.class "buttons" ]
                    [ H.button [ E.onClick GetFromLocalStorageReq ] [ H.text "Get" ]
                    , H.button [ E.onClick SetToLocalStorage ] [ H.text "Set" ]
                    , H.button [ E.onClick ClearLocalStorage ] [ H.text "Clear" ]
                    , H.div [ A.class "foobar" ] []
                    ]
                ]
            ]
        ]
            ++ viewSourceFiles model.sourceFiles


viewSourceFiles : List SourceFile -> List (Html Msg)
viewSourceFiles =
    List.indexedMap <|
        \index sourceFile ->
            H.div [ A.class "codeViewerContainer" ]
                [ H.h3 [] [ H.text sourceFile.name ]
                , H.node "code-viewer"
                    [ A.attribute "editor-value" sourceFile.content
                    , E.on "editorChanged" <| JD.map (UpdSourceCode index) <| JD.at [ "detail", "value" ] <| JD.string
                    ]
                    []
                ]


viewLabeledInput : String -> String -> (String -> msg) -> Html msg
viewLabeledInput label value msg =
    H.p [ A.class "row" ]
        [ H.label []
            [ H.span [ A.class "label" ] [ H.text (label ++ ":") ]
            , H.input [ A.value value, E.onInput msg ] []
            ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        currentKey =
            model.localStorageFormKey

        currentValue =
            model.localStorageFormValue
    in
    case msg of
        UpdLocalStorageFormKey newKey ->
            ( { model | localStorageFormKey = newKey }, Cmd.none )

        UpdLocalStorageFormValue newValue ->
            ( { model | localStorageFormValue = newValue }, Cmd.none )

        GetFromLocalStorageReq ->
            ( { model | waitingForJs = True }, localStorageGetReq { key = currentKey } )

        GetFromLocalStorageResp newValue ->
            ( { model | waitingForJs = False, localStorageFormValue = newValue }, Cmd.none )

        SetToLocalStorage ->
            ( model, localStorageSet { key = currentKey, value = currentValue } )

        ClearLocalStorage ->
            ( { model | localStorageFormKey = "", localStorageFormValue = "" }, localStorageClear () )

        UpdSourceCode updateIndex newContent ->
            let
                updateByIndex =
                    \index sourceFile ->
                        if index == updateIndex then
                            { sourceFile | content = newContent }

                        else
                            sourceFile

                updatedSourceFiles =
                    List.indexedMap updateByIndex model.sourceFiles
            in
            ( { model | sourceFiles = updatedSourceFiles }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions =
    always <| localStorageGetResp (\{ value } -> GetFromLocalStorageResp value)
