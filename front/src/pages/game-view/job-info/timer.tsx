import * as React from 'react';
import { TimerInfo } from '../defs';
import { observer } from 'mobx-react';
import { timerString } from '../../../util/time-string';
import { bind } from 'bind-decorator';
import { FontAwesomeIcon } from '../../../util/icon';

export interface IPropTimer {
  timer: TimerInfo;
}
export interface IStateTimer {
  /**
   * Remaining time (in milliseconds).
   */
  remaining: number;
}

// workaround of decorator function's type being not inferred.
const observerForTimer: (clazz: typeof Timer) => typeof Timer = observer;
/**
 * Timer display.
 */
@observerForTimer
export class Timer extends React.Component<IPropTimer, IStateTimer> {
  protected timerid: any = null;
  constructor(props: IPropTimer) {
    super(props);
    this.state = {
      remaining: 0,
    };
  }
  public render() {
    const {
      props: {
        timer: { enabled, name },
      },
      state: { remaining },
    } = this;

    if (!enabled) {
      // Render nothing if timer is disabled now.
      return null;
    }
    // Make a string representation of remaining time.
    const timerStr = timerString(remaining >= 0 ? remaining : 0);
    return (
      <>
        <FontAwesomeIcon icon={['far', 'clock']} /> {name} {timerStr}
      </>
    );
  }
  static getDerivedStateFromProps(
    props: Readonly<IPropTimer>,
  ): Partial<IStateTimer> | null {
    // Derive current remaining time as soon as props is updated.
    if (props.timer.enabled) {
      return {
        remaining: props.timer.target - Date.now(),
      };
    } else {
      return null;
    }
  }
  public componentDidMount() {
    // Start counting if timer is enabled.
    if (this.props.timer.enabled) {
      this.startTimer();
    }
  }
  public componentDidUpdate(prevProps: IPropTimer) {
    // start/stop timer according to props change.
    if (prevProps.timer.enabled && !this.props.timer.enabled) {
      this.stopTimer();
    } else if (!prevProps.timer.enabled && this.props.timer.enabled) {
      this.startTimer();
    }
  }
  public componentWillUnmount() {
    if (this.timerid != null) {
      this.stopTimer();
    }
  }
  private startTimer() {
    console.assert(this.timerid == null);
    this.timerid = setInterval(this.updateRemaining, 1000);
  }
  private stopTimer() {
    console.assert(this.timerid != null);
    clearInterval(this.timerid);
    this.timerid = null;
  }
  @bind
  private updateRemaining() {
    // Update state using current time.
    this.setState({
      remaining: this.props.timer.target - Date.now(),
    });
  }
}
