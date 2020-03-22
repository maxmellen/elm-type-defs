port module Main exposing (main)

import Browser
import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Http
import Json.Decode as JD
import Regex exposing (Regex)


port localStorageGetReq : { key : String } -> Cmd msg


port localStorageGetResp : ({ value : String } -> msg) -> Sub msg


port localStorageSet : { key : String, value : String } -> Cmd msg


port localStorageClear : () -> Cmd msg


type CodeView
    = Loading { filename : String }
    | Loaded
        { filename : String
        , contents : String
        , mode : String
        }


type alias Flags =
    { title : String
    , filenames : List String
    }


type alias Model =
    { title : String
    , codeViews : List CodeView
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
    | GotSourceFile Int (Result Http.Error String)
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
        codeViews =
            flags.filenames
                |> List.map (\name -> Loading { filename = name })

        initialState =
            { title = flags.title
            , codeViews = codeViews
            , waitingForJs = False
            , localStorageFormKey = ""
            , localStorageFormValue = ""
            }
    in
    ( initialState, Cmd.batch <| List.indexedMap getSourceFile codeViews )


getSourceFile : Int -> CodeView -> Cmd Msg
getSourceFile index codeView =
    case codeView of
        Loading { filename } ->
            Http.get
                { url = "./src/" ++ filename
                , expect = Http.expectString <| GotSourceFile index
                }

        _ ->
            Cmd.none


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
            ++ viewCodeViews model.codeViews


viewCodeViews : List CodeView -> List (Html Msg)
viewCodeViews =
    List.indexedMap <|
        \index codeView ->
            case codeView of
                Loaded { filename, contents, mode } ->
                    H.div [ A.class "codeViewerContainer" ]
                        [ H.h3 [] [ H.text filename ]
                        , H.node "code-viewer"
                            [ A.attribute "editor-value" contents
                            , A.attribute "mode" mode
                            , E.on "editorChanged" <| JD.map (UpdSourceCode index) <| JD.at [ "detail", "value" ] <| JD.string
                            ]
                            []
                        ]

                _ ->
                    H.div [] []


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

        GotSourceFile updateIndex httpResult ->
            let
                updateByIndex contents =
                    \index codeView ->
                        case codeView of
                            Loading { filename } ->
                                if index == updateIndex then
                                    Loaded { filename = filename, contents = contents, mode = inferMode filename }

                                else
                                    codeView

                            _ ->
                                codeView

                updatedCodeViews =
                    case httpResult of
                        Ok sourceCode ->
                            List.indexedMap (updateByIndex sourceCode) model.codeViews

                        _ ->
                            model.codeViews
            in
            ( { model | codeViews = updatedCodeViews }, Cmd.none )

        UpdSourceCode updateIndex updatedContents ->
            let
                updateByIndex =
                    \index codeView ->
                        case codeView of
                            Loaded loadedView ->
                                if index == updateIndex then
                                    Loaded { loadedView | contents = updatedContents }

                                else
                                    codeView

                            _ ->
                                codeView

                updatedCodeViews =
                    List.indexedMap updateByIndex model.codeViews
            in
            ( { model | codeViews = updatedCodeViews }, Cmd.none )


inferMode : String -> String
inferMode filename =
    let
        extension =
            filename
                |> Regex.find fileExtension
                |> List.head
                |> Maybe.map .submatches
                |> Maybe.andThen List.head
                |> Maybe.withDefault Nothing
                |> Maybe.withDefault ""
    in
    case extension of
        "ts" ->
            "javascript"

        "elm" ->
            "elm"

        _ ->
            ""


fileExtension : Regex
fileExtension =
    Regex.fromString "\\.(\\w+)$"
        |> Maybe.withDefault Regex.never


subscriptions : Model -> Sub Msg
subscriptions =
    always <| localStorageGetResp (\{ value } -> GetFromLocalStorageResp value)
