/**
 * Information of your job, typically sent from server.
 */
export interface RoleInfo extends RolePeersInfo, RoleOtherPlayerInfo {
  /**
   * Name of current job.
   */
  jobname: string;
  /**
   * Whether you are dead.
   */
  dead: boolean;
  /**
   * Descriptions provided to you.
   */
  desc: RoleDesc[];
  /**
   * Kind of speech available now.
   */
  speak: string[];
  /**
   * Content of will.
   */
  will: string | undefined;
  /**
   * Whether the player won the game.
   * null is for not determined.
   */
  win: boolean | null;
  /**
   * Your team.
   */
  myteam?: string;
  /**
   * Your player number when quantum werewolf.
   */
  quantumwerewolf_number?: number;
  /**
   * Info of player which you support.
   */
  supporting?: PublicPlayerInfo & {
    supportingJob: string;
  };
  /**
   * Info of currently open forms.
   */
  forms: FormDesc[];
}

/**
 * Part of RoleInfo which consists of information of other players.
 */
export type RolePeersInfo = Record<
  | 'wolves'
  | 'peers'
  | 'madpeers'
  | 'foxes'
  | 'nobles'
  | 'queens'
  | 'spy2s'
  | 'friends'
  | 'cultmembers'
  | 'vampires'
  | 'twins',
  PublicPlayerInfo[] | undefined
>;
/**
 * Part of RoleInfo which consists of information of one other player.
 */
export type RoleOtherPlayerInfo = Record<
  'stalking' | 'dogOwner',
  PublicPlayerInfo | undefined
>;

/**
 * Object of info of user.
 */
export interface PublicPlayerInfo {
  /**
   * ID of this player.
   */
  id: string;
  /**
   * Display name of this player.
   */
  name: string;
  /**
   * Whether this player is dead.
   */
  dead: boolean;
  /**
   * Whether this player shows norevival flag.
   */
  norevive: boolean;
}
export interface RoleDesc {
  /**
   * Name of role.
   */
  name: string;
  /**
   * Id of role.
   */
  type: string;
}
export type FormType = 'required' | 'optional' | 'optionalOnce';
export interface FormDesc {
  /**
   * Type of this form.
   */
  type: string;
  /**
   * Options for this form.
   */
  options: FormOption[];
  /**
   * Type of requiredness.
   */
  formType: FormType;
  /**
   * ID of owner of this form.
   */
  objid: string;
}
export interface FormOption {
  /**
   * Label of this option.
   */
  name: string;
  /**
   * Value sent to server.
   */
  value: string;
}
/**
 * Provided info of game.
 */
export interface GameInfo {
  /**
   * Current day.
   */
  day: number;
  /**
   * Status of game.
   */
  status: 'waiting' | 'playing' | 'finished';
}

/**
 * State of speaking form.
 */
export interface SpeakState {
  /**
   * Size of comment.
   */
  size: 'small' | 'normal' | 'big';
  /**
   * Kind of speech.
   */
  kind: string;
  /**
   * Multiline or not.
   */
  multiline: boolean;
  /**
   * Whether will form is open.
   */
  willOpen: boolean;
}

/**
 * visibility of logs per day.
 */
export type LogVisibility = LogAll | LogToday | LogOneDay;

export interface LogAll {
  type: 'all';
}
export interface LogToday {
  type: 'today';
}
export interface LogOneDay {
  type: 'one';
  day: number;
}

/**
 * Current status of timer.
 */
export interface TimerInfo {
  /**
   * Whether timer is currently enabled.
   */
  enabled: boolean;
  /**
   * Displayed name of timer.
   */
  name: string;
  /**
   * Target time of countdown (in ms).
   */
  target: number;
}

/**
 * One player in player list.
 */
export interface PlayerInfo {
  /**
   * userid of player.
   */
  id: string;
  /**
   * realid of player.
   */
  realid: string | null;
  /**
   * Whether this player is anonymized.
   */
  anonymous: boolean;
  /**
   * Displayed name of this player.
   */
  name: string;
  /**
   * Whether this player is dead.
   */
  dead: boolean;
  /**
   * URL of icon of this player.
   */
  icon: string | null;
  /**
   * Whether this player is a winner.
   * Null indicates that game is not finished yet.
   */
  winner: boolean | null;
  /**
   * Displayed jobname.
   */
  jobname: string | null;
  /**
   * Flags enabled for this player.
   */
  flags: Array<'ready' | 'helper' | 'gm' | 'norevive'>;
}

/**
 * State of room before starting.
 */
export interface RoomPrelude {
  type: 'prelude';
  /**
   * Whether you are an owner.
   */
  owner: boolean;
  /**
   * Whether you have already joined the room.
   */
  joined: boolean;
  /**
   * Whether this room is old.
   */
  old: boolean;
  /**
   * Whether this room is blind mode.
   */
  blind: boolean;
}
/**
 * State of room after the end.
 */
export interface RoomPostlude {
  type: 'postlude';
}
export type RoomControlInfo = RoomPrelude | RoomPostlude;

/**
 * Query of speaking.
 */
export interface SpeakQuery {
  /**
   * Comment string.
   */
  comment: string;
  /**
   * Type of comment.
   */
  mode: string;
  /**
   * Size of comment.
   */
  size: 'big' | '' | 'small';
}

/**
 * Base of log.
 */
export interface LogBase {
  time: number;
}

/**
 * Normal Log.
 */
export interface NormalLog extends LogBase {
  /**
   * Type of this log.
   */
  mode:
    | 'day'
    | 'system'
    | 'werewolf'
    | 'heaven'
    | 'prepare'
    | 'skill'
    | 'audience'
    | 'monologue'
    | 'couple'
    | 'fox'
    | 'will'
    | 'userinfo'
    | 'madcouple'
    | 'wolfskill'
    | 'emmaskill'
    | 'eyeswolfskill'
    | 'half-day'
    | 'heavenmonologue'
    | 'voteto'
    | 'gm'
    | 'gmreply'
    | 'gmheaven'
    | 'gmaudience'
    | 'gmmonologue'
    | 'helperwhisper'
    | 'inlog';
  /**
   * Content of this log.
   */
  comment: string;
  /**
   * Userid.
   */
  userid: string;
  /**
   * Displayed name of speaker.
   */
  name?: string;
  /**
   * Target of this log.
   */
  to: string | null;
  /**
   * Size of comment.
   */
  size?: 'big' | 'small';
}

/**
 * Phase change log.
 */
export interface NextTurnLog extends LogBase {
  mode: 'nextturn';
  comment: string;
  /**
   * Day number of this log.
   */
  day: number;
  /**
   * Whether this is night.
   */
  night: boolean;
  /**
   * Whether this is a finished log.
   */
  finished?: boolean;
}

/**
 * Vote result log.
 */
export interface VoteResultLog extends LogBase {
  mode: 'voteresult';
  /**
   * Result of all votes.
   */
  voteresult: Array<{
    id: string;
    name: string;
    voteto: string;
  }>;
  /**
   * Dictionary of all voting.
   */
  tos: Record<string, number | undefined>;
}

/**
 * Probability table log.
 */
export interface ProbabilityTableLog extends LogBase {
  mode: 'probability_table';
  /**
   * Probability table attached to this log.
   */
  probability_table: Record<
    string,
    {
      name: string;
      Human: number;
      Diviner: number;
      Werewolf: number;
      dead: number;
    }
  >;
}

/**
 * Type of log.
 */
export type Log = NormalLog | NextTurnLog | ProbabilityTableLog | VoteResultLog;
