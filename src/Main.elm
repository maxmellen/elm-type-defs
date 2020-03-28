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
            ( { model | waitingForJs = True }, localStorageGetReq { key = model.localStorageFormKey } )

        GetFromLocalStorageResp newValue ->
            ( { model | waitingForJs = False, localStorageFormValue = newValue }, Cmd.none )

        SetToLocalStorage ->
            ( model, localStorageSet { key = model.localStorageFormKey, value = model.localStorageFormValue } )

        ClearLocalStorage ->
            ( { model | localStorageFormKey = "", localStorageFormValue = "" }, localStorageClear () )

        GotSourceFile index result ->
            let
                codeViews =
                    result
                        |> Result.map (\contents -> updateByIndex (loadCodeView contents) index model.codeViews)
                        |> Result.withDefault model.codeViews
            in
            ( { model | codeViews = codeViews }, Cmd.none )

        UpdSourceCode index contents ->
            let
                codeViews =
                    updateByIndex (updateCodeView <| always contents) index model.codeViews
            in
            ( { model | codeViews = codeViews }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions =
    always <| localStorageGetResp (\{ value } -> GetFromLocalStorageResp value)


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
            codeView
                |> mapCodeView
                    (\( filename, contents, mode ) ->
                        H.div [ A.class "codeViewerContainer" ]
                            [ H.h3 [] [ H.text filename ]
                            , H.node "code-viewer"
                                [ A.attribute "editor-value" contents
                                , A.attribute "mode" mode
                                , E.on "editorChanged" <|
                                    JD.map (UpdSourceCode index) <|
                                        JD.at [ "detail", "value" ] <|
                                            JD.string
                                ]
                                []
                            ]
                    )
                |> Maybe.withDefault (H.div [] [])


updateByIndex : (a -> a) -> Int -> List a -> List a
updateByIndex f i =
    List.indexedMap <|
        \i_ a ->
            if i_ == i then
                f a

            else
                a


loadCodeView : String -> CodeView -> CodeView
loadCodeView contents codeView =
    case codeView of
        Loading { filename } ->
            Loaded
                { filename = filename
                , contents = contents
                , mode = inferMode filename
                }

        _ ->
            codeView


updateCodeView : (String -> String) -> CodeView -> CodeView
updateCodeView f codeView =
    case codeView of
        Loaded { filename, contents, mode } ->
            Loaded
                { filename = filename
                , contents = f contents
                , mode = mode
                }

        _ ->
            codeView


mapCodeView : (( String, String, String ) -> a) -> CodeView -> Maybe a
mapCodeView f codeView =
    case codeView of
        Loaded { filename, contents, mode } ->
            Just <| f ( filename, contents, mode )

        _ ->
            Nothing


inferMode : String -> String
inferMode filename =
    let
        extension =
            filename
                |> (Regex.find fileExtensionRegex >> List.head)
                |> Maybe.andThen (.submatches >> List.head >> Maybe.withDefault Nothing)
                |> Maybe.withDefault ""
    in
    case extension of
        "ts" ->
            "javascript"

        "elm" ->
            "elm"

        _ ->
            ""


fileExtensionRegex : Regex
fileExtensionRegex =
    Regex.fromString "\\.(\\w+)$"
        |> Maybe.withDefault Regex.never
