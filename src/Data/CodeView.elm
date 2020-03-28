module Data.CodeView exposing (CodeView(..), error, load, update)

import Regex exposing (Regex)


type CodeView
    = Loading { filename : String }
    | Loaded
        { filename : String
        , contents : String
        , mode : String
        }
    | Errored
        { filename : String
        , message : String
        }


load : String -> CodeView -> CodeView
load contents codeView =
    case codeView of
        Loading { filename } ->
            Loaded
                { filename = filename
                , contents = contents
                , mode = inferMode filename
                }

        _ ->
            codeView


error : String -> CodeView -> CodeView
error message codeView =
    let
        errored filename =
            Errored { filename = filename, message = message }
    in
    case codeView of
        Loading { filename } ->
            errored filename

        Loaded { filename } ->
            errored filename

        _ ->
            codeView


update : (String -> String) -> CodeView -> CodeView
update f codeView =
    case codeView of
        Loaded { filename, contents, mode } ->
            Loaded
                { filename = filename
                , contents = f contents
                , mode = mode
                }

        _ ->
            codeView


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
