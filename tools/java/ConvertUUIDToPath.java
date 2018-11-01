import java.util.UUID;

public class ConvertUUIDToPath {

	public static void main(String[] args) {
		
		if (args.length != 1) {
			System.out.println("Usage...");
			System.exit(1);
		}
		
		String input = args[0];
		
		// First see if the input is in proper UUID format (with hyphens)
		boolean isInUUIDFormat = input.indexOf('-') != -1 ? true : false;
		
		// If the input is not in proper UUID format, add the hyphens
		if (!isInUUIDFormat) {
			try {
				input = input.substring(0,8) + "-" + input.substring(8,12) + "-" + input.substring(12,16) + "-" + input.substring(16,20) + "-" + input.substring(20);
			} 
			catch (StringIndexOutOfBoundsException e) {
				System.err.println("Invalid UUID");
				System.exit(1);
			}
		}
		
		// Create a UUID from the input and get the directory components
		try {
			UUID uuid = UUID.fromString(input);
			int dir1 = (int)Math.abs(uuid.getMostSignificantBits() % 128L);
			int dir2 = (int)Math.abs(uuid.getLeastSignificantBits() % 128L);
			System.out.println("File path: " + dir1 + "/" + dir2);
		} 
		catch (IllegalArgumentException e) {
			System.err.println("Invalid UUID");
			System.exit(1);
		}
		
	}

}