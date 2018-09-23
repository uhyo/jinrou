import * as React from 'react';
import styled, { withProps } from '../../../util/styled';
import { bind } from '../../../util/bind';
import { TranslationFunction } from 'i18next';

interface IPropWillForm {
  t: TranslationFunction;
  /**
   * Whether the will form is open.
   */
  open: boolean;
  /**
   * Content of will.
   */
  will: string | undefined;
  /**
   * Handle of will update.
   */
  onWillChange: (content: string) => void;
}
interface IStateWillForm {
  changed: boolean;
}
/**
 * Form of will.
 */
export class WillForm extends React.PureComponent<
  IPropWillForm,
  IStateWillForm
> {
  protected textareaRef: React.RefObject<HTMLTextAreaElement>;
  static getDerivedStateFromProps(props: IPropWillForm, state: IStateWillForm) {
    if (props.open === false) {
      return { changed: false };
    } else {
      return null;
    }
  }
  constructor(props: IPropWillForm) {
    super(props);
    this.state = {
      changed: false,
    };
    this.textareaRef = React.createRef();
  }
  public render() {
    const { t, open } = this.props;
    const { changed } = this.state;
    return (
      <Wrapper open={open} onSubmit={this.handleSubmit}>
        <Content>
          <p>
            {t('game_client:speak.will.message')}
            {changed ? (
              <>
                {'　'}
                <em>{t('game_client:speak.will.changed')}</em>
              </>
            ) : null}
          </p>
          <p>
            <textarea ref={this.textareaRef} onChange={this.handleChange} />
            <input type="submit" value={t('game_client:speak.will.save')} />
          </p>
        </Content>
      </Wrapper>
    );
  }
  public componentDidUpdate(prevProps: IPropWillForm): void {
    if (
      this.props.will !== prevProps.will ||
      (this.props.open && !prevProps.open)
    ) {
      // Changed will causes a forced update to DOM.
      if (this.textareaRef.current) {
        this.textareaRef.current.value = this.props.will || '';
      }
    }
  }
  /**
   * Handle a submission of will form.
   */
  @bind
  protected handleSubmit(e: React.SyntheticEvent<any>) {
    const { onWillChange } = this.props;
    onWillChange(
      (this.textareaRef.current && this.textareaRef.current.value) || '',
    );
    e.preventDefault();
  }
  /**
   * Handle a change to the textarea.
   */
  @bind
  protected handleChange() {
    this.setState({
      changed: true,
    });
  }
}

/**
 * Wrapper of will form.
 */
const Wrapper = withProps<{
  open: boolean;
}>()(styled.form)`
  transition: height 250ms ease-out;
  height: ${({ open }) => (open ? '7em' : '0')};

  background-color: #636363;
  color: #ffffff;
  overflow-y: hidden;
`;

const Content = styled.div`
  margin: 0.4em;

  em {
    font-style: normal;
    color: #ffff00;
    font-size: smaller;
  }

  textarea {
    width: 40em;
    height: 4em;
    vertical-align: text-bottom;
  }
`;
