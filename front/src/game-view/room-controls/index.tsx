import * as React from 'react';
import { RoomPreludeHandlers } from '../../defs';
import { bind } from 'bind-decorator';
import {
  showPlayerDialog,
  showSelectDialog,
  showKickDialog,
  showConfirmDialog,
} from '../../dialog';
import { TranslationFunction } from '../../i18n';
import { PlayerInfo } from '../defs';

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
   * Whether you have already joined to to the room.
   */
  joined: boolean;
  /**
   * Whether you are an owner of the room.
   */
  owner: boolean;
  /**
   * Whether this room is old.
   */
  old: boolean;
  /**
   * Whether this room is in blind mode.
   */
  blind: boolean;
  /**
   * List of players in this room.
   */
  players: PlayerInfo[];
  /**
   * Handlers for UI events.
   */
  handlers: RoomPreludeHandlers;
}
/**
 * Buttons to control rooms, used before a game starts.
 */
export class RoomControls extends React.Component<IPropRoomControls, {}> {
  public render() {
    const { joined, owner, old, handlers } = this.props;
    return (
      <div>
        {joined ? (
          <>
            <button type="button" onClick={handlers.unjoin}>
              ゲームから脱退
            </button>
            <button
              type="button"
              title="全員が準備完了になるとゲームを開始できます。"
              onClick={handlers.ready}
            >
              準備完了/準備中
            </button>
            <button
              type="button"
              title="ヘルパーになると、ゲームに参加せずに助言役になります。"
              onClick={this.handleHelperClick}
            >
              ヘルパー
            </button>
          </>
        ) : (
          <button type="button" onClick={this.handleJoinClick}>
            ゲームに参加
          </button>
        )}
        {owner ? (
          <>
            <button type="button" onClick={handlers.openGameStart}>
              ゲーム開始画面を開く
            </button>
            <button type="button" onClick={this.handleKickClick}>
              参加者を追い出す
            </button>
            <button type="button" onClick={this.handleResetReady}>
              [ready]を初期化する
            </button>
          </>
        ) : null}
        {owner || old ? (
          <button type="button" onClick={this.handleDiscard}>
            この部屋を廃村にする
          </button>
        ) : null}
      </div>
    );
  }
  /**
   * Handle a click of the join button.
   */
  @bind
  private handleJoinClick(): void {
    const { t, blind, handlers } = this.props;
    // if the room is in blind mode,
    // show user info dialog.
    if (blind) {
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
