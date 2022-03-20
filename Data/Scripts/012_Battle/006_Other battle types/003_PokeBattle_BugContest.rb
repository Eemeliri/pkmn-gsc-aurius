#===============================================================================
# Bug Catching Contest battle scene (the visuals of the battle)
#===============================================================================
class PokeBattle_Scene
  alias _bugContest_pbInitSprites pbInitSprites

  def pbInitSprites
    _bugContest_pbInitSprites
    # "helpwindow" shows the currently caught Pokémon's details when asking if
    # you want to replace it with a newly caught Pokémon.
    @sprites["helpwindow"] = Window_UnformattedTextPokemon.newWithSize("",0,0,32,32,@viewport)
    @sprites["helpwindow"].z       = 200
    @sprites["helpwindow"].visible = false
  end

  def pbShowHelp(text)
    @sprites["helpwindow"].resizeToFit(text,Graphics.width)
    @sprites["helpwindow"].y       = 0
    @sprites["helpwindow"].x       = 0
    @sprites["helpwindow"].text    = text
    @sprites["helpwindow"].visible = true
  end

  def pbHideHelp
    @sprites["helpwindow"].visible = false
  end
end



#===============================================================================
# Bug Catching Contest battle class
#===============================================================================
class PokeBattle_BugContestBattle < PokeBattle_Battle
  attr_accessor :ballCount

  def initialize(*arg)
    @ballCount = 0
    @ballConst = getConst(PBItems,:SPORTBALL) || -1
    super(*arg)
  end

  def pbItemMenu(idxBattler,_firstAction)
    return pbRegisterItem(idxBattler,@ballConst,1)
  end

  def pbCommandMenu(idxBattler,_firstAction)
    return @scene.pbCommandMenuEx(idxBattler,[
       _INTL("LEFT/\n{1} balls",@ballCount),
       _INTL("FIGHT"),
       _INTL("SPORTBALLx{1}",@ballCount),
       _INTL("POKéMON"),
       _INTL("RUN")
    ],4)
  end

  def pbConsumeItemInBag(_item,_idxBattler)
    @ballCount -= 1 if @ballCount>0
  end

  def pbStorePokemon(pkmn)
    if pbBugContestState.lastPokemon
      lastPokemon = pbBugContestState.lastPokemon
      pbDisplayPaused(_INTL("You already caught a {1}.",lastPokemon.name))
      helptext = _INTL("STOCK @*:\nHP: {3}\n{1}({2})\nTHIS @*:\nHP: {6}\n{4}({5})",
         lastPokemon.name,lastPokemon.level,lastPokemon.totalhp,
         pkmn.name,pkmn.level,pkmn.totalhp
      )
      @scene.pbShowHelp(helptext)
      if pbDisplayConfirm(_INTL("Switch them?"))
        pbBugContestState.lastPokemon = pkmn
        @scene.pbHideHelp
      else
        @scene.pbHideHelp
        return
      end
    else
      pbBugContestState.lastPokemon = pkmn
    end
    pbDisplay(_INTL("Caught {1}!",pkmn.name))
  end

  def pbEndOfRoundPhase
    super
    @decision = 3 if @ballCount<=0 && @decision==0
  end
end
