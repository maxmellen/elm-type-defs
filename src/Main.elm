module Main exposing (main)

import Browser
import Html as H exposing (Html)


type alias Flags =
    { foo : String
    , bar : Int
    }


type alias Model =
    { message : String }


type Msg
    = NoOp


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
    ( Model <| Debug.toString flags, Cmd.none )


view : Model -> Html Msg
view model =
    H.text <| "Here we are again: " ++ model.message


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
