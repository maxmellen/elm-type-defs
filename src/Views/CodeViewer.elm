module Views.CodeViewer exposing (Attributes, view)

import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Json.Decode as JD


type alias Attributes msg =
    { title : String
    , editorValue : String
    , mode : Maybe String
    , readOnly : Bool
    , onChanged : Maybe (String -> msg)
    }


view : Attributes msg -> Html msg
view attributes =
    let
        baseAttrs =
            [ A.attribute "editor-value" attributes.editorValue
            , A.attribute "mode" (attributes.mode |> Maybe.withDefault "")
            ]

        onChangeAttrs =
            attributes.onChanged
                |> Maybe.map
                    (\onChanged ->
                        E.on "editorChanged" <|
                            JD.map onChanged <|
                                JD.at [ "detail", "value" ] <|
                                    JD.string
                    )
                |> Maybe.map List.singleton
                |> Maybe.withDefault []

        attrs =
            baseAttrs ++ onChangeAttrs
    in
    H.div [ A.class "codeViewerContainer" ]
        [ H.h3 [] [ H.text attributes.title ]
        , H.node "code-viewer" attrs []
        ]
