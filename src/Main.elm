module Main exposing (main)

import Browser
import Data.CodeView as CodeView exposing (CodeView)
import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Http
import Ports.LocalStorage as LocalStorage
import Views.CodeViewer as CodeViewer


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
                |> List.map (\name -> CodeView.Loading { filename = name })

        initialState =
            { title = flags.title
            , codeViews = codeViews
            , waitingForJs = False
            , localStorageFormKey = ""
            , localStorageFormValue = ""
            }
    in
    ( initialState, Cmd.batch <| List.indexedMap getSourceFile codeViews )


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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdLocalStorageFormKey key ->
            ( { model | localStorageFormKey = key }, Cmd.none )

        UpdLocalStorageFormValue value ->
            ( { model | localStorageFormValue = value }, Cmd.none )

        GetFromLocalStorageReq ->
            ( { model | waitingForJs = True }, LocalStorage.getReq model.localStorageFormKey )

        GetFromLocalStorageResp newValue ->
            ( { model | waitingForJs = False, localStorageFormValue = newValue }, Cmd.none )

        SetToLocalStorage ->
            ( model, LocalStorage.set model.localStorageFormKey model.localStorageFormValue )

        ClearLocalStorage ->
            ( { model | localStorageFormKey = "", localStorageFormValue = "" }, LocalStorage.clear )

        GotSourceFile index result ->
            let
                codeViews =
                    case result of
                        Ok contents ->
                            updateByIndex (CodeView.load contents) index model.codeViews

                        Err _ ->
                            updateByIndex (CodeView.error "File not found.") index model.codeViews
            in
            ( { model | codeViews = codeViews }, Cmd.none )

        UpdSourceCode index contents ->
            let
                codeViews =
                    updateByIndex (CodeView.update <| always contents) index model.codeViews
            in
            ( { model | codeViews = codeViews }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions =
    always <| LocalStorage.getResp GetFromLocalStorageResp


getSourceFile : Int -> CodeView -> Cmd Msg
getSourceFile index codeView =
    case codeView of
        CodeView.Loading { filename } ->
            Http.get
                { url = "./src/" ++ filename
                , expect = Http.expectString <| GotSourceFile index
                }

        _ ->
            Cmd.none


viewLabeledInput : String -> String -> (String -> msg) -> Html msg
viewLabeledInput label value msg =
    H.p [ A.class "row" ]
        [ H.label []
            [ H.span [ A.class "label" ] [ H.text (label ++ ":") ]
            , H.input [ A.value value, E.onInput msg ] []
            ]
        ]


viewCodeViews : List CodeView -> List (Html Msg)
viewCodeViews =
    List.indexedMap <|
        \index codeView ->
            case codeView of
                CodeView.Loading { filename } ->
                    CodeViewer.view
                        { title = filename
                        , editorValue = "Loading..."
                        , mode = Nothing
                        , readOnly = True
                        , onChanged = Nothing
                        }

                CodeView.Loaded { filename, contents, mode } ->
                    CodeViewer.view
                        { title = filename
                        , editorValue = contents
                        , mode = Just mode
                        , readOnly = False
                        , onChanged = Just <| UpdSourceCode index
                        }

                CodeView.Errored { filename, message } ->
                    CodeViewer.view
                        { title = filename
                        , editorValue = message
                        , mode = Nothing
                        , readOnly = True
                        , onChanged = Nothing
                        }


updateByIndex : (a -> a) -> Int -> List a -> List a
updateByIndex f i =
    List.indexedMap <|
        \i_ a ->
            if i_ == i then
                f a

            else
                a
