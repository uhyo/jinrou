import * as React from 'react';
import { RoomControlHandlers } from '../../../defs';
import { bind } from 'bind-decorator';
import {
  showPlayerDialog,
  showSelectDialog,
  showKickDialog,
  showConfirmDialog,
} from '../../../dialog';
import { TranslationFunction } from '../../../i18n';
import { PlayerInfo, RoomControlInfo } from '../defs';

export interface IPropRoomControls {
  /**
   * Translation function.
   */
  t: TranslationFunction;
  /**
   * ID of room.
   */
  roomid: number;
  /**
   * Status of room controls.
   */
  roomControls: RoomControlInfo;
  /**
   * List of players in this room.
   */
  players: PlayerInfo[];
  /**
   * Handlers for UI events.
   */
  handlers: RoomControlHandlers;
}
/**
 * Buttons to control rooms, used before a game starts.
 */
export class RoomControls extends React.Component<IPropRoomControls, {}> {
  public render() {
    const { t, roomControls, handlers } = this.props;
    if (roomControls.type === 'prelude') {
      // Show prelude.
      const { joined, old, owner } = roomControls;
      return (
        <>
          {joined ? (
            <>
              <button type="button" onClick={handlers.unjoin}>
                {t('game_client:room.unjoin')}
              </button>
              <button
                type="button"
                title={t('game_client:room.readyDescription')}
                onClick={handlers.ready}
              >
                {t('game_client:room.ready')}
              </button>
              <button
                type="button"
                title={t('game_client:room.helperDescription')}
                onClick={this.handleHelperClick}
              >
                {t('game_client:room.helper')}
              </button>
            </>
          ) : (
            <button type="button" onClick={this.handleJoinClick}>
              {t('game_client:room.join')}
            </button>
          )}
          {owner ? (
            <>
              <button type="button" onClick={handlers.openGameStart}>
                {t('game_client:room.openGameStart')}
              </button>
              <button type="button" onClick={this.handleKickClick}>
                {t('game_client:room.kick')}
              </button>
              <button type="button" onClick={this.handleResetReady}>
                {t('game_client:room.resetReady')}
              </button>
            </>
          ) : null}
          {owner || old ? (
            <button type="button" onClick={this.handleDiscard}>
              {t('game_client:room.discard')}
            </button>
          ) : null}
        </>
      );
    } else if (roomControls.type === 'endless') {
      const { joined } = roomControls;
      return joined ? null : (
        <button type="button" onClick={this.handleJoinClick}>
          {t('game_client:room.join')}
        </button>
      );
    } else {
      // show postlude.
      return (
        <>
          <button type="button" onClick={handlers.newRoom}>
            {t('game_client:room.newRoom')}
          </button>
        </>
      );
    }
  }
  /**
   * Handle a click of the join button.
   */
  @bind
  private handleJoinClick(): void {
    const { t, roomControls, handlers } = this.props;
    const blind =
      (roomControls.type === 'prelude' || roomControls.type === 'endless') &&
      roomControls.blind;
    const theme = roomControls.type === 'prelude' && roomControls.theme;
    // if the room is in blind mode,
    // show user info dialog.
    if (blind && !theme) {
      showPlayerDialog({
        modal: true,
        title: t('game_client:room.playerDialog.title'),
        message: t('game_client:room.playerDialog.message'),
        ok: t('game_client:room.playerDialog.ok'),
        cancel: t('game_client:room.playerDialog.cancel'),
      })
        .then(user => {
          if (user != null) {
            handlers.join(user);
          }
        })
        .catch(err => console.error(err));
    } else {
      handlers.join({
        name: '',
        icon: null,
      });
    }
  }
  /**
   * Handle a click of helper button.
   */
  @bind
  private async handleHelperClick() {
    const { t, players, handlers } = this.props;
    const target = await showSelectDialog({
      modal: true,
      title: t('game_client:room.helperDialog.title'),
      message: t('game_client:room.helperDialog.message'),
      ok: t('game_client:room.helperDialog.ok'),
      cancel: t('game_client:room.helperDialog.cancel'),
      options: [
        {
          label: t('game_client:room.helperDialog.nohelper'),
          value: '',
        },
      ].concat(players.map(({ name, id }) => ({ label: name, value: id }))),
    });
    if (target == null) {
      // cancellation
      return;
    }
    // convert '' to null so that 'no helper' can be selected
    handlers.helper(target || null);
  }
  /**
   * Handle a click of kick button.
   */
  @bind
  private async handleKickClick() {
    const { roomid, players, handlers } = this.props;
    const target = await showKickDialog({
      modal: true,
      roomid,
      players,
    });
    if (target == null) {
      // cancellation
      return;
    }
    if (target.type === 'kick') {
      handlers.kick(target);
    } else {
      handlers.kickRemove(target.users);
    }
  }
  /**
   * Handle a click of reset ready button.
   */
  @bind
  private async handleResetReady() {
    const { t, handlers } = this.props;
    const conf = await showConfirmDialog({
      modal: true,
      title: t('game_client:room.resetReadyDialog.title'),
      message: t('game_client:room.resetReadyDialog.message'),
      yes: t('game_client:room.resetReadyDialog.yes'),
      no: t('game_client:room.resetReadyDialog.no'),
    });
    if (conf) {
      handlers.resetReady();
    }
  }
  /**
   * Handle a click of discard button.
   */
  @bind
  private async handleDiscard() {
    const { t, handlers } = this.props;
    const conf = await showConfirmDialog({
      modal: true,
      title: t('game_client:room.discardDialog.title'),
      message: t('game_client:room.discardDialog.message'),
      yes: t('game_client:room.discardDialog.yes'),
      no: t('game_client:room.discardDialog.no'),
    });
    if (conf) {
      handlers.discard();
    }
  }
}
