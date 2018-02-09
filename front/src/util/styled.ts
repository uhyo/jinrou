// https://github.com/styled-components/styled-components/issues/630#issuecomment-317277803
import {
    ThemedStyledFunction,
} from 'styled-components';

// usage: const Button = withProps<ButtonProps>()(styled.div)`...`
export const withProps = <U>() =>
    <P, T, O>(
        fn: ThemedStyledFunction<P, T, O>
    ): ThemedStyledFunction<P & U, T, O & U> => (fn as ThemedStyledFunction<P & U, T, O & U>);
