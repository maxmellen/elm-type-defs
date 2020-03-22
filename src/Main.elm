port module Main exposing (main)

import Browser
import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E


port localStorageGetReq : { key : String } -> Cmd msg


port localStorageGetResp : ({ value : String } -> msg) -> Sub msg


port localStorageSet : { key : String, value : String } -> Cmd msg


port localStorageClear : () -> Cmd msg


type alias Flags =
    { title : String
    }


type alias Model =
    { title : String
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
            , waitingForJs = False
            , localStorageFormKey = ""
            , localStorageFormValue = ""
            }
    in
    ( initialState, Cmd.none )


view : Model -> Html Msg
view model =
    H.fieldset [ A.disabled model.waitingForJs ]
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


subscriptions : Model -> Sub Msg
subscriptions model =
    localStorageGetResp (\{ value } -> GetFromLocalStorageResp value)
