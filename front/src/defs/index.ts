/**
 * Definition of casting.
 */
export interface CastingDefinition {
    /**
     * ID of this casting.
     */
    id: string;
    /**
     * name of this casting.
     */
    name: string;
    /**
     * Whether this casting allows user selection of roles.
     */
    roleSelect: boolean;
    /**
     * Function to define this casting.
     */
    preset?: (players: number)=> Record<string, number>;
}


