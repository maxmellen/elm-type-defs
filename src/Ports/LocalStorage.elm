port module Ports.LocalStorage exposing (clear, getReq, getResp, set)


getReq : String -> Cmd msg
getReq key =
    localStorageGetReq { key = key }


getResp : (String -> msg) -> Sub msg
getResp handleResp =
    localStorageGetResp <| \{ value } -> handleResp value


set : String -> String -> Cmd msg
set key value =
    localStorageSet { key = key, value = value }


clear : Cmd msg
clear =
    localStorageClear ()


port localStorageGetReq : { key : String } -> Cmd msg


port localStorageGetResp : ({ value : String } -> msg) -> Sub msg


port localStorageSet : { key : String, value : String } -> Cmd msg


port localStorageClear : () -> Cmd msg
