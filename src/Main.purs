module Main where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Class (class MonadEffect)
import Effect.Console as Console
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.VDom.Driver (runUI)
import LZString (compressToEncodedURIComponent, decompressFromEncodedURIComponent)
import LocationString (getFragmentString, setFragmentString)
import Web.DOM (NonElementParentNode)
import Web.DOM.Document (toNonElementParentNode)
import Web.DOM.Element (Element)
import Web.DOM.NonElementParentNode (getElementById)
import Web.HTML (window)
import Web.HTML.HTMLDocument (toDocument)
import Web.HTML.HTMLTextAreaElement (HTMLTextAreaElement)
import Web.HTML.HTMLTextAreaElement as HTMLTextAreaElement
import Web.HTML.Window (document)

main :: Effect Unit
main = HA.runHalogenAff do
  body <- HA.awaitBody
  H.liftEffect loadTablatureFromFragment
  runUI component unit body

data State = ViewMode | EditMode

data Action = Save

component :: forall query input output m. MonadEffect m => H.Component query input output m
component =
  H.mkComponent
    { initialState
    , render
    , eval: H.mkEval H.defaultEval { handleAction = handleAction }
    }

initialState :: forall input. input -> State
initialState _ = ViewMode

render :: forall m. State -> H.ComponentHTML Action () m
render state =
  HH.div_
    [ renderHeader
    , renderButton
    , renderTextarea
    ]

renderHeader = HH.h1_ [HH.text "Dozenal Tablature Viewer"]
renderButton = HH.button [ HE.onClick \_ -> Save ] [ HH.text "Save" ]
renderTextarea = HH.textarea [ HP.classes [HH.ClassName "textinput"], HP.placeholder "Paste your plaintext tablature here" ]

handleAction :: forall output m. MonadEffect m => Action -> H.HalogenM State Action () output m Unit
handleAction = case _ of
  Save -> H.liftEffect saveTablatureToFragment

saveTablatureToFragment :: Effect Unit
saveTablatureToFragment = do
  string <- getTablatureText
  case compressToEncodedURIComponent string of
    Just compressed -> setFragmentString compressed
    Nothing -> Console.error("Could not save tablature to URL")

loadTablatureFromFragment :: Effect Unit
loadTablatureFromFragment = do
  string <- getFragmentString
  case decompressFromEncodedURIComponent string of
    Just decompressed -> setTablatureText decompressed
    Nothing -> Console.error("Could not load tablature from URL")

getDocument :: Effect NonElementParentNode
getDocument = window >>= document <#> toDocument <#> toNonElementParentNode

documentGetElementById :: String -> Effect (Maybe Element)
documentGetElementById id = getDocument >>= getElementById id

getTablatureTextArea :: Effect (Maybe HTMLTextAreaElement)
getTablatureTextArea =
  documentGetElementById "textareaTablature" <#>
  (\maybeElement -> maybeElement >>= HTMLTextAreaElement.fromElement)

getTablatureText :: Effect String
getTablatureText = do
  maybeTextArea <- getTablatureTextArea
  case maybeTextArea of
    Nothing -> Console.error "Could not find textareaTablature" *> pure ""
    Just textArea -> HTMLTextAreaElement.value textArea 

setTablatureText :: String -> Effect Unit
setTablatureText text = do
  maybeTextArea <- getTablatureTextArea
  case maybeTextArea of
    Nothing -> Console.error "Could not find textareaTablature" *> pure unit
    Just textArea -> HTMLTextAreaElement.setValue text textArea 
