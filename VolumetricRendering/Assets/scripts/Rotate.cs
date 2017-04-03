using UnityEngine;

public class Rotate : MonoBehaviour
{
	public float Rate;
    public bool RotateCube;

    private void Update()
    {
        RotateEverything();
    }

    private void RotateEverything()
    {
        if (!RotateCube) return;

        //Rotation
        var oldRot = transform.rotation.eulerAngles;
        var newY = oldRot.y + Rate * Time.deltaTime;
        transform.rotation = Quaternion.Euler(oldRot.x, newY, oldRot.z);
    }
}
